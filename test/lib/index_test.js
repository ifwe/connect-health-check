/*jshint expr: true*/

// Your npm package is accessible by requiring `LIB_DIR`.
var MyNpmPackage = require(LIB_DIR);

describe('MyNpmPackage', function() {
    it('exists', function() {
        MyNpmPackage.should.exist;
    });
});
