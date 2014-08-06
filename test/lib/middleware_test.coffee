healthCheck = require "#{LIB_DIR}/middleware"
cluster = require 'cluster'

describe 'healthCheck', ->
    describe 'middleware', ->
        beforeEach ->
            @req = url: '/'
            @res =
                writeHead: sinon.spy()
                end: sinon.spy()
            @next = sinon.spy()

        it 'is a function', ->
            healthCheck.should.be.a 'function'

        it 'returns a function', ->
            healthCheck().should.be.a 'function'

        describe 'default route', ->
            beforeEach ->
                @middleware = healthCheck() # use default options

            it 'calls `next()` if `req.url` does not match default `/health.json`', ->
                @middleware @req, @res, @next
                @next.called.should.be.true

            it 'responds with health object if `req.url` matches default `/health.json`', ->
                @req.url = '/health.json'
                @middleware @req, @res, @next
                @res.writeHead.calledOnce.should.be.true
                @res.writeHead.lastCall.args[0].should.equal 200
                @res.writeHead.lastCall.args[1].should.deep.equal 'Content-Type': 'application/json'

        describe 'configurable route', ->
            beforeEach ->
                @middleware = healthCheck '/test/health.json' # configurable route

            it 'responds with health object if `req.url` matches configured url', ->
                @req.url = '/test/health.json'
                @middleware @req, @res, @next
                @res.writeHead.calledOnce.should.be.true
                @res.writeHead.lastCall.args[0].should.equal 200
                @res.writeHead.lastCall.args[1].should.deep.equal 'Content-Type': 'application/json'

            it 'calls next() if `req.url` does not match default `/health.json`', ->
                @req.url = '/health.json' # should not match, because the default was overwritten
                @middleware @req, @res, @next
                @next.called.should.be.true

        describe 'health object', ->
            beforeEach ->
                @middleware = healthCheck() # use default options
                @req.url = '/health.json' # ensure health object is returned
                sinon.stub(process, 'uptime').returns('uptime_canary')
                sinon.stub(process, 'memoryUsage').returns('memory_canary');

            afterEach ->
                process.uptime.restore()
                process.memoryUsage.restore()

            it 'contains `status` property set to "OK"', ->
                @middleware @req, @res, @next
                body = JSON.parse @res.end.lastCall.args[0]
                body.should.have.property 'status', 'OK'

            it 'contains `arch` property set to `process.arch`', ->
                @middleware @req, @res, @next
                body = JSON.parse @res.end.lastCall.args[0]
                body.should.have.property 'arch', process.arch

            it 'contains `pid` property set to `process.pid`', ->
                @middleware @req, @res, @next
                body = JSON.parse @res.end.lastCall.args[0]
                body.should.have.property 'pid', process.pid

            it 'contains `uptime` property set to `process.uptime()`', ->
                @middleware @req, @res, @next
                body = JSON.parse @res.end.lastCall.args[0]
                body.should.have.property 'uptime', 'uptime_canary'

            it 'contains `memory` property set to `process.memoryUsage()`', ->
                @middleware @req, @res, @next
                body = JSON.parse @res.end.lastCall.args[0]
                body.should.have.property 'memory', 'memory_canary'
        describe 'cluster master', ->
            beforeEach ->
                @middleware = healthCheck() # use default options
                @req.url = '/health.json' # ensure health object is returned
                sinon.stub(process, 'uptime').returns('uptime_canary')
                sinon.stub(process, 'memoryUsage').returns('memory_canary');
                # cluster.isMaster = true
                cluster.workers =
                    abc:
                        process:
                            id: 'abc'
                            arch: 'abc_arch_canary'
                            pid: 'abc_pid_canary'
                    def:
                        process:
                            id: 'def'
                            arch: 'def_arch_canary'
                            pid: 'def_pid_canary'

            afterEach ->
                cluster.workers = null
                process.uptime.restore()
                process.memoryUsage.restore()

            it 'contains health for each worker', ->
                @middleware @req, @res, @next
                body = JSON.parse @res.end.lastCall.args[0]
                body.should.have.property 'workers'
                body.workers.should.be.an 'array'
                body.workers.should.have.lengthOf 2
                body.workers[0].should.contain
                    status: 'OK'
                    id: 'abc'
                    arch: 'abc_arch_canary'
                    pid: 'abc_pid_canary'
                    uptime: null # uptime is not available in child processes :(
                    memory: null # memory usage is not available in child processes :(
                body.workers[1].should.contain
                    status: 'OK'
                    id: 'def'
                    arch: 'def_arch_canary'
                    pid: 'def_pid_canary'
                    uptime: null # uptime is not available in child processes :(
                    memory: null # memory usage is not available in child processes :(
