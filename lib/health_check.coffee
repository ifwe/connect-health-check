# Middleware for connect that responds with a health check
# if the request path matches the provided path
middleware = (path, req, res, next) ->
    return next() if req.path != path

    res.send
        status: 'OK'
        arch: process.arch
        pid: process.pid
        uptime: process.uptime()
        memory: process.memoryUsage()

# Returns a middleware function
# bound with the provided path.
# If omitted, the path defaults to `/health.json`.
factory = (path = '/health.json') -> middleware.bind @, path

# Expose the factory
module.exports = factory
