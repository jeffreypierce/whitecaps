module.exports = (grunt) ->

  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'

    coffee:
      dist:
        options:
          join: true
        files:
          'js/app.js': [
            'app/scripts/spectrum.coffee'
            'app/scripts/audio.coffee'
            'app/scripts/whitecap.coffee'
            'app/scripts/app.coffee'
            'app/scripts/controllers.coffee'
            'app/scripts/directives.coffee'
            'app/scripts/services.coffee'
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
          'index.html': ['app/views/index.jade']
    sass:
      dist:
        options:
          outputStyle: 'compressed'
        files:
          'css/app.css': 'app/styles/app.scss'

    autoprefixer:
      dist:
        files:
          'css/app.css':'css/app.css'

    watch:
      tasks: ['coffee', 'jade', 'sass', 'autoprefixer']
      files: [
          'app/**/*'
        ]
      options:
        livereload: true

    uglify:
      my_target:
        files:
          'js/vendor.min.js': [
            'bower_components/jquery/dist/jquery.min.js'
            'bower_components/angular/angular.min.js'
            'bower_components/underscore/underscore.js'
          ]


    connect:
      server:
        options:
          port: 8888
          base: ''


  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-jade'
  grunt.loadNpmTasks 'grunt-contrib-connect'
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-sass'
  grunt.loadNpmTasks 'grunt-autoprefixer'

  grunt.registerTask 'default', ['coffee', 'jade', 'sass', 'autoprefixer']
  grunt.registerTask 'vendor', ['uglify']
  grunt.registerTask 'server', ['default', 'connect', 'watch']
