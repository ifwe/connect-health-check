healthCheck = require "#{LIB_DIR}/health_check"

describe 'healthCheck', ->
    describe 'middleware', ->
        beforeEach ->
            @req = path: '/'
            @res = send: sinon.spy()
            @next = sinon.spy()

        it 'is a function', ->
            healthCheck.should.be.a 'function'

        it 'returns a function', ->
            healthCheck().should.be.a 'function'

        describe 'default route', ->
            beforeEach ->
                @middleware = healthCheck() # use default options

            it 'calls `next()` if `req.path` does not match default `/health.json`', ->
                @middleware @req, @res, @next
                @next.called.should.be.true

            it 'responds with health object if path matches default `/health.json`', ->
                @req.path = '/health.json'
                @middleware @req, @res, @next
                @res.send.calledOnce.should.be.true
                @res.send.lastCall.args[0].should.be.an 'object'

        describe 'configurable route', ->
            beforeEach ->
                @middleware = healthCheck '/test/health.json' # configurable route

            it 'responds with health object if path matches configured route', ->
                @req.path = '/test/health.json'
                @middleware @req, @res, @next
                @res.send.calledOnce.should.be.true
                @res.send.lastCall.args[0].should.be.an 'object'

            it 'calls next() if path does not match default `/health.json`', ->
                @req.path = '/health.json' # should not match, because the default was overwritten
                @middleware @req, @res, @next
                @next.called.should.be.true

        describe 'health object', ->
            beforeEach ->
                @middleware = healthCheck() # use default options
                @req.path = '/health.json' # ensure health object is returned
                sinon.stub(process, 'uptime').returns('uptime_canary')
                sinon.stub(process, 'memoryUsage').returns('memory_canary');

            afterEach ->
                process.uptime.restore()
                process.memoryUsage.restore()

            it 'contains `status` property set to "OK"', ->
                @middleware @req, @res, @next
                @res.send.lastCall.args[0].should.have.property 'status', 'OK'

            it 'contains `arch` property set to `process.arch`', ->
                @middleware @req, @res, @next
                @res.send.lastCall.args[0].should.have.property 'arch', process.arch

            it 'contains `pid` property set to `process.pid`', ->
                @middleware @req, @res, @next
                @res.send.lastCall.args[0].should.have.property 'pid', process.pid

            it 'contains `uptime` property set to `process.uptime()`', ->
                @middleware @req, @res, @next
                @res.send.lastCall.args[0].should.have.property 'uptime', 'uptime_canary'

            it 'contains `memory` property set to `process.memoryUsage()`', ->
                @middleware @req, @res, @next
                @res.send.lastCall.args[0].should.have.property 'memory', 'memory_canary'
