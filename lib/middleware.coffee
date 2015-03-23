Promise = require 'bluebird'
cluster = require 'cluster'
childProcess = require 'child_process'

EVENT_NAME = 'tagged.health'

# Returns the health of the provided process
health = (process) ->
    status: 'OK'
    id: if cluster.isWorker then cluster.worker.id else 'master'
    arch: process.arch
    pid: process.pid
    uptime: if process.uptime? then process.uptime() else null
    memory: if process.memoryUsage? then process.memoryUsage() else null
    env: process.env

# Keeps track of event IDs
eventId = 0

# Keeps track of deferred promises
deferreds = {}

# Sends message to provided worker to respond back with health info
resolver = (worker, resolve, reject) ->
    eventId++

    worker.send
        event: EVENT_NAME
        id: eventId
        time: process.hrtime()

    deferreds[eventId] =
        resolve: resolve
        reject: reject
        timeout: setTimeout reject, 1000

# Writes a health check response
respondWithHealth = (req, res, results) ->
    data = health process

    if cluster.isMaster
        data.workers = []

        for result in results
            if result.isRejected()
                data.workers.push status: 'DOWN'
            else
                data.workers.push result.value().health

    res.writeHead 200, 'Content-Type': 'application/json'
    res.end JSON.stringify data

# Middleware for connect that responds with a health check
# if the request path matches the provided path
middleware = (path, req, res, next) ->
    return next() if req.url != path

    promises = []

    if cluster.isMaster
        for id, worker of cluster.workers
            promises.push new Promise resolver.bind(null, worker)

    Promise.settle(promises)
    .then(respondWithHealth.bind(null, req, res))

# Register a worker listener each time a worker is forked
onFork = (worker) ->
    worker.on 'message', onWorkerMessage

# Callback for messages sent by workers
onWorkerMessage = (msg) ->
    return unless msg.event == EVENT_NAME
    return unless deferreds[msg.id]?
    diff = process.hrtime msg.time
    msg.health.latency = diff[0] * 1e9 + diff[1]
    deferreds[msg.id].resolve msg
    clearTimeout deferreds[msg.id].timeout

    # Cleanup
    deferreds[msg.id] = null
    delete deferreds[msg.id]

# Callback for messages sent by master
onMasterMessage = (msg) ->
    return unless msg.event == EVENT_NAME
    msg.health = health process
    process.send msg

# Returns a middleware function bound with the provided path.
# If omitted, the path defaults to `/health.json`.
module.exports = (path = '/health.json', callback = null) ->
    if cluster.isMaster
        cluster.on 'fork', onFork
    else
        process.on 'message', onMasterMessage

    middleware.bind @, path
