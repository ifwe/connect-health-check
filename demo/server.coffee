health = require '../lib'

options =
    port: 3000
    path: '/health.json'

health.server options, ->
    console.log "Health check server is running on port 3000. Visit http://localhost:3000/health.json to view health."
