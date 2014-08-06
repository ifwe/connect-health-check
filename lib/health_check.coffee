cluster = require 'cluster'
childProcess = require 'child_process'

# Returns the health of the provided process
health = (process, id) ->
    status: 'OK'
    id: id
    arch: process.arch
    pid: process.pid
    uptime: if process.uptime? then process.uptime() else null
    memory: if process.memoryUsage? then process.memoryUsage() else null

# Returns an array of health objects for each worker
workersHealth = (workers) ->
    healths = []
    for id, worker of workers
        healths.push health worker.process, id
    return healths

# Middleware for connect that responds with a health check
# if the request path matches the provided path
middleware = (path, req, res, next) ->
    return next() if req.path != path

    id = if cluster.isWorker then cluster.worker.id else 'master'
    data = health process, id
    data.workers = workersHealth cluster.workers if cluster.isMaster

    res.send data

# Returns a middleware function
# bound with the provided path.
# If omitted, the path defaults to `/health.json`.
factory = (path = '/health.json') -> middleware.bind @, path

# Expose the factory
module.exports = factory
