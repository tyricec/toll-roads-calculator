module.exports = (grunt) ->
  grunt.initConfig({
    "db": grunt.file.readJSON('db.json'),
    "deployments": {
      "options": {
        "backups_dir": "db_backups"
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
