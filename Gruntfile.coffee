module.exports = (grunt) ->
  grunt.initConfig({
    "db": grunt.file.readJSON('db.json'),
    "shell": {
      "createTestDB": {
        "command": "mysql -utyricec -e\"DROP DATABASE IF EXISTS ditisfu_calculator; CREATE DATABASE IF NOT EXISTS ditisfu_calculator;\""
      }    
    },
    "coffee": {
      "compileMain": {
        "options": {
          "bare": true,
          "join": true
        },
        "files": {
          "js/map.js": ["coffee/marker.coffee", "coffee/map.coffee"]
        }
      },
      "compileServices": {
        "options": {
          "bare": true
        },
        "files": {
          "js/services.js": ["coffee/services.coffee"]
        }
      }
    },
    "watch": {
      "coffee": {
        "files": ["coffee/*.coffee"],
        "tasks": ["coffee:compileMain", "coffee:compileServices"]
      }
    },
    "deployments": {
      "options": {
        "backups_dir": "db_backups",
        "target": "develop_test"
      },
      "local": {
        "title": "Local",
        "database": "<%= db.local.db_name %>",
        "user": "<%= db.local.db_user %>",
        "pass": "<%= db.local.db_password %>",
        "host": "localhost"
      },
      "develop": {
        "title": "Development",
        "database": "<%= db.remote.db_name %>",
        "user": "<%= db.remote.db_user %>",
        "pass": "<%= db.remote.db_password %>",
        "host": "<%= db.remote.host %>",
        "ssh_host": "<%= db.remote.ssh_host %>"
      }
      "develop_test": {
        "title": "Development",
        "database": "<%= db.remote.db_name %>_test",
        "user": "<%= db.remote.db_user %>",
        "pass": "<%= db.remote.db_password %>",
        "host": "<%= db.remote.host %>",
        "ssh_host": "<%= db.remote.ssh_host %>"
      }
    },
    "replace" : {
      "remote_db" : {
        "src": "php/config.php",
        "dest": "php/config.php",
        "replacements": [
          {
            "from": /\('DB_HOST'.*(?!\))/,
            "to": "('DB_HOST', '<%= db.local.host %>');"
          },
          {
            "from": /\('DB_NAME'.*(?!\))/,
            "to": "('DB_NAME', '<%= db.local.db_name %>');"
          },
          {
            "from": /\('DB_USER'.*(?!\))/,
            "to": "('DB_USER', '<%= db.local.db_user %>');"
          },
          {
            "from": /\('DB_PASS'.*(?!\))/,
            "to": "('DB_PASS', '<%= db.local.db_password %>');"
          },
        ],
      },
      "local_db" : {
        "src": "php/config.php",
        "dest": "php/config.php",
        "replacements": [
          {
            "from": /\('DB_HOST'.*(?!\))/,
            "to": "('DB_HOST', '<%= db.remote.host %>');"
          },
          {
            "from": /\('DB_NAME'.*(?!\))/,
            "to": "('DB_NAME', '<%= db.remote.db_name %>');"
          },
          {
            "from": /\('DB_USER'.*(?!\))/,
            "to": "('DB_USER', '<%= db.remote.db_user %>');"
          },
          {
            "from": /\('DB_PASS'.*(?!\))/,
            "to": "('DB_PASS', '<%= db.remote.db_password %>');"
          },
        ]
      },
    }
  })
  grunt.loadNpmTasks('grunt-text-replace')
  grunt.loadNpmTasks('grunt-deployments')
  grunt.loadNpmTasks('grunt-shell')
  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-contrib-watch')
  grunt.registerTask('loadTestDB', ['shell:createTestDB', 'db_pull'])
