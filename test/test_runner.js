require('coffeescript');
var path = require('path');

// Use constant to help with resolving path to lib code within test files
global.LIB_DIR = path.join(process.cwd(), 'lib');

// Set up in-place instrumentation for code coverage
require('blanket')({ pattern: LIB_DIR });

// Set up sinon
global.sinon = require('sinon');

// Set up chai
global.chai = require('chai');
chai.should();
global.assert = chai.assert;
global.expect = chai.expect;
chai.config.includeStack = true;
