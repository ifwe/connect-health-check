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
      }
    }
