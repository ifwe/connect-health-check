http = require 'http'
connect = require 'connect'
health = require '../lib'
cluster = require 'cluster'
cpus = require('os').cpus().length
port = 3000
workers = Math.ceil(cpus / 2)
listeners = 0

onListen = ->
    console.log "New worker started with PID #{@process.pid}"
    listeners++
    console.log "Multi-core server listening on port #{port}" if listeners == workers

startWorker = ->
    worker = cluster.fork()
    worker.on 'listening', onListen.bind(worker)

if cluster.isMaster
    cluster.on 'exit', (worker, code, signal) ->
        console.error "Worker PID #{worker.process.pid} died with exit code #{worker.process.exitCode}, restarting..."
        startWorker()

    console.log "Starting server with #{workers} workers"

    for i in [0...workers] by 1
        startWorker()

    options =
        port: 3001
        path: '/health.json'

    health.server options, ->
        console.log "Master health check listening on port #{options.port} at #{options.path}"

    # Randomly kill a worker every 2 seconds
    setInterval ->
        workers = []
        for name, worker of cluster.workers
            workers.push worker
        rand = Math.floor(Math.random() * workers.length)
        workers[rand].kill(0);
    , 2000
else
    app = connect()
    app.use health.middleware()
    http.createServer(app).listen(port)
