Promise = require 'bluebird'
healthCheck = require "#{LIB_DIR}/middleware"
cluster = require 'cluster'
os = require 'os'

describe 'healthCheck', ->
    describe 'middleware', ->
        beforeEach ->
            @req = url: '/'
            @res =
                writeHead: sinon.spy()
                end: sinon.spy()
            @next = sinon.spy()
            sinon.stub(os, 'hostname').returns 'test os'

        # Kill all listeners on cluster
        afterEach ->
            cluster.isMaster = false
            cluster.workers = {}
            cluster.removeAllListeners()
            os.hostname.restore()

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

            it 'responds with health object if `req.url` matches default `/health.json`', (done) ->
                @req.url = '/health.json'
                @res.end = sinon.spy =>
                    @res.writeHead.calledOnce.should.be.true
                    @res.writeHead.lastCall.args[0].should.equal 200
                    @res.writeHead.lastCall.args[1].should.deep.equal 'Content-Type': 'application/json'
                    @res.end.calledOnce.should.be.true
                    done()
                @middleware @req, @res, @next
                return

            it 'returns 503 response if any hosts are down', (done) ->
                cluster.isMaster = true
                cluster.workers = {
                    # Using a string in place of a function throws an error, causing the promise
                    # to be rejected. This is a dirty hack but works around the issue of not being
                    # able to mock responses from workers.
                    0: { send: 'fail' }
                }
                @req.url = '/health.json'
                @res.writeHead = sinon.spy()
                @res.end = sinon.spy =>
                    @res.writeHead.calledOnce.should.be.true
                    @res.writeHead.calledWith(503, sinon.match.any).should.be.true
                    done()
                @middleware @req, @res, @next
                return

        describe 'configurable route', ->
            beforeEach ->
                @middleware = healthCheck '/test/health.json' # configurable route

            it 'responds with health object if `req.url` matches configured url', (done) ->
                @res.end = =>
                    @res.writeHead.calledOnce.should.be.true
                    @res.writeHead.lastCall.args[0].should.equal 200
                    @res.writeHead.lastCall.args[1].should.deep.equal 'Content-Type': 'application/json'
                    done()
                @req.url = '/test/health.json'
                @middleware @req, @res, @next
                return

            it 'calls next() if `req.url` does not match default `/health.json`', (done) ->
                @next = sinon.spy ->
                    done()
                @req.url = '/health.json' # should not match, because the default was overwritten
                @middleware @req, @res, @next
                @next.called.should.be.true
                return

        describe 'health object', ->
            beforeEach ->
                @middleware = healthCheck() # use default options
                @req.url = '/health.json' # ensure health object is returned
                sinon.stub(process, 'uptime').returns('uptime_canary')
                sinon.stub(process, 'memoryUsage').returns('memory_canary')

            afterEach ->
                process.uptime.restore()
                process.memoryUsage.restore()

            it 'contains `status` property set to "OK"', (done) ->
                @res.end = (body) ->
                    body = JSON.parse body
                    body.should.have.property 'status', 'OK'
                    done()
                @middleware @req, @res, @next
                return

            it 'contains `arch` property set to `process.arch`', (done) ->
                @res.end = (body) ->
                    body = JSON.parse body
                    body.should.have.property 'arch', process.arch
                    done()
                @middleware @req, @res, @next
                return

            it 'contains `pid` property set to `process.pid`', (done) ->
                @res.end = (body) ->
                    body = JSON.parse body
                    body.should.have.property 'pid', process.pid
                    done()
                @middleware @req, @res, @next
                return

            it 'contains `uptime` property set to `process.uptime()`', (done) ->
                @res.end = (body) ->
                    body = JSON.parse body
                    body.should.have.property 'uptime', 'uptime_canary'
                    done()
                @middleware @req, @res, @next
                return

            it 'contains `memory` property set to `process.memoryUsage()`', (done) ->
                @res.end = (body) ->
                    body = JSON.parse body
                    body.should.have.property 'memory', 'memory_canary'
                    done()
                @middleware @req, @res, @next
                return

            it 'contains `env` property set to `process.env`', (done) ->
                @res.end = (body) ->
                    body = JSON.parse body
                    body.should.have.property 'env'
                    body.env.should.deep.equal process.env
                    done()
                @middleware @req, @res, @next
                return

            it 'contains `hostname` property set to `os.hostname()`', (done) ->
                @res.end = (body) ->
                    body = JSON.parse body
                    body.should.have.property 'hostname'
                    body.hostname.should.equal 'test os'
                    done()
                @middleware @req, @res, @next
                return

            it 'contains `version` property set to `node.version`', (done) ->
                @res.end = (body) ->
                    body = JSON.parse body
                    body.should.have.property 'version'
                    body.version.should.deep.equal process.version
                    done()
                @middleware @req, @res, @next
                return

        # TODO: Find a way to mock events sent from workers to master process
        # or a way to trigger master process events on demand.
        # Maybe use event emitter?
        describe.skip 'cluster master', ->
            beforeEach ->
                @middleware = healthCheck() # use default options
                @req.url = '/health.json' # ensure health object is returned
                sinon.stub(process, 'uptime').returns('uptime_canary')
                sinon.stub(process, 'memoryUsage').returns('memory_canary');
                cluster.isMaster = true
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

            it 'contains health for each worker', (done) ->
                @res.end = sinon.spy =>
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
                    done()
                @middleware @req, @res, @next
                return

