connect = require 'connect'
middleware = require './middleware'

module.exports = (options = {}, done) ->
    app = connect()
    app.use middleware options.path
    app.listen options.port or 3000, done
