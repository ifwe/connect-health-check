var path = require('path');

module.exports = function(grunt) {
    var TEST_RUNNER = path.join(process.cwd(), 'test', 'test_runner');
    var ALL_TESTS = 'test/**/*_test.coffee';

    // NPM tasks, alphabetical
    grunt.loadNpmTasks('grunt-contrib-clean');
    grunt.loadNpmTasks('grunt-contrib-watch');
    grunt.loadNpmTasks('grunt-docco');
    grunt.loadNpmTasks('grunt-mocha-test');
    grunt.loadNpmTasks('grunt-bump');

    grunt.initConfig({
        //Bump up version
        bump: {
            options: {
                files: ['package.json'],
                updateConfigs: [],
                commit: true,
                commitMessage: 'Release v%VERSION%',
                commitFiles: ['package.json'],
                createTag: true,
                tagName: 'v%VERSION%',
                tagMessage: 'Version %VERSION%',
                push: true,
                pushTo: 'origin',
                gitDescribeOptions: '--tags --always --abbrev=1 --dirty=-d',
                globalReplace: false,
                prereleaseName: false,
                regExp: false
            }
        },

        // Clean
        clean: {
            docs: ['docs'],
            coverage: ['test/coverage.html']
        },

        // Documentation
        docco: {
            main: {
                src: ['lib/**/*.coffee', 'lib/**/*.js'],
                options: {
                    output: 'docs/'
                }
            }
        },

        // Server-side mocha tests
        mochaTest: {
            // Runs all tests
            test: {
                options: {
                    require: TEST_RUNNER,
                    reporter: 'spec',
                    ui: 'bdd',
                    timeout: 200,
                    recursive: true,
                    clearRequireCache: true
                },
                src: [ALL_TESTS]
            },

            // Instruments code for reporting test coverage
            instrument: {
                options: {
                    require: TEST_RUNNER,
                    reporter: 'spec',
                    ui: 'bdd',
                    timeout: 200,
                    recursive: true,
                },
                src: [ALL_TESTS]
            },

            // Reports test coverage
            coverage: {
                options: {
                    require: TEST_RUNNER,
                    reporter: 'html-cov',
                    ui: 'bdd',
                    timeout: 200,
                    recursive: true,
                    quiet: true,
                    captureFile: 'test/coverage.html'
                },
                src: [ALL_TESTS]
            }
        },

        // Watches filesystem for changes to run tasks automatically
        watch: {
            test: {
                options: {
                    spawn: false
                },
                files: [
                    'lib/**/*.coffee',
                    'test/**/*.coffee'
                ],
                tasks: ['mochaTest:test']
            }
        }
    });

    // Runs all unit tests
    grunt.registerTask('test', 'All unit tests', ['mochaTest:test']);

    // Generates test coverage report
    grunt.registerTask('coverage', 'Unit test code coverage', ['clean:coverage', 'mochaTest:instrument', 'mochaTest:coverage']);

    // Generates documentation
    grunt.registerTask('docs', 'Generate documentation', ['clean:docs', 'docco:main']);
};
