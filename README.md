Health check for Connect.
=========================

Installation:
-------------

    $ npm install tagged-health

Usage:
------

The health check can be registered as middleware in any Connect app:

    var connect = require('connect');
    var health = require('tagged-health');
    var app = connect();

    // Default health check on `/health.json`:
    app.use(health.middleware());

    // Custom health check path:
    app.use(health.middleware('/my/custom/health.json');

The health check responds with the following data:

    {
      "status": "OK",
      "arch": "x64",
      "pid": 1234,
      "uptime": 456,
      "memory": {
        "rss": 15208448,
        "heapTotal": 7195904,
        "heapUsed": 3183048
      },
      workers: []
    }

Cluster Support:
----------------

If you're using the cluster module, a master health check can be created on its own port:

    var health = require('tagged-health');
    health.server({
        path: '/health.json',   // path to health check (default: /health.json)
        port: 3000              // port to listen on (default: 3000)
    }, function() {
        console.log("Master health check listening on port 3000 at /health.json")
    });
