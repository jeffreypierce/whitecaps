module.exports = (grunt) ->

  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'

    coffee:
      dist:
        options:
          join: true
        files:
          'dist/app.js': [
            'app/scripts/whitecap.coffee'
            'app/scripts/spectrum.coffee'
            'app/scripts/app.coffee'
            'app/scripts/controllers.coffee'
            'app/scripts/directives.coffee'
          ]

    # copy:
    #   dist:
    #     expand: true
    #     filter: 'isFile'
    #     src: 'assets/*'
    #     dest: 'dist/'

    jade:
      dist:
        options:
          data:
            debug: false
        files:
          'dist/index.html': ['app/views/index.jade']
    sass:
      dist:
        options:
          #outputStyle: 'compressed'
          includePaths: [
          # quiet: true
          # loadPath: [
            # 'bower_components/bourbon/app/assets/stylesheets'
            # 'bower_components/neat/app/assets/stylesheets'
            # 'bower_components/css-modal/'
          ]
        files:
          'dist/app.css': 'app/styles/app.scss'

    watch:
      tasks: ['coffee', 'jade', 'sass']
      files: [
          'app/**/*'
        ]
      options:
        livereload: true

    uglify:
      my_target:
        files:
          'dist/vendor.min.js': [
            'bower_components/jquery/dist/jquery.min.js'
            'bower_components/angular/angular.min.js'
            'bower_components/angular-animate/angular-animate.min.js'
            'bower_components/underscore/underscore.js'
          ]


    connect:
      server:
        options:
          port: 8888
          base: 'dist'


  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-jade'
  grunt.loadNpmTasks 'grunt-contrib-connect'
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-sass'

  grunt.registerTask 'default', ['coffee', 'jade', 'sass', 'uglify']
  grunt.registerTask 'vendor', ['uglify']
  grunt.registerTask 'server', ['connect', 'watch']
