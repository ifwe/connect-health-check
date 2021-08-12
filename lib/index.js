require('coffeescript');
require('coffeescript/register');
module.exports.middleware = require('./middleware');
module.exports.server = require('./server');
