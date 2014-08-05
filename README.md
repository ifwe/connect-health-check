Health check for Connect.
=========================

Installation:
-------------

    $ npm install tagged-health-check

Usage:
------

The health check can be registered as middleware in any Connect app:

    var connect = require('connect');
    var healthCheck = require('tagged-health-check');
    var app = connect();

    // Default health check on `/health.json`:
    app.use(healthCheck());

    // Custom health check path:
    app.use(healthCheck('/my/custom/health.json');

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
      }
    }
