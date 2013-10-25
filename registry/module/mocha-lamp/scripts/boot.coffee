#!/usr/bin/env coffee

child_process = require "child_process"
fs            = require "fs"

message = (str) ->
  console.log JSON.stringify ["message", str]

spawn = (name, cmd, params = [], options = {}) ->
  options.detached = true
  options.stdio = ["ignore", fout, ferr]

  proc = child_process.spawn cmd, params, options

  proc.unref()

fout = fs.openSync '/out.log', 'a'
ferr = fs.openSync '/out.log', 'a'

checkMysql = ->
  child_process.exec "mysql -uroot -e ''", (err, stdout, stderr) ->
    ready = stderr.search(/ERROR/) is -1

    return runTests() if ready

    setTimeout checkMysql, 200

runTests = ->
  options =
    cwd: "/var/www"
    env: process.env

  args = process.argv[2..]

  ###
  # @TODO need to think about what command is actually run and from where
  # yes, the original horde app was solely to run a specific suite in a
  # specific container, but can we defer to a more flexible runner here?
  # e.g. something like grunt test, phing test, npm test - etc etc, and
  # does this command have to even be specified here? Why can't it be
  # an argument just like any other, making the *docker* image in which
  # this lives more agnostic and re-usable...
  ###
  runner = child_process.spawn "./node_modules/mocha/bin/_mocha", args, options

  runner.stdout.on "data", (data) -> process.stdout.write data

  runner.on "exit", (code) ->
    console.log "[runner] exit #{code}"
    ###
    # we can't just kill these child processes since they spawn their own
    # sub procs; we have to properly stop the services
    # no need for any callbacks; when these exit we'll be left with no more
    # processes so the parent will naturally exit itself
    child_process.exec "mysqladmin shutdown", ->
      console.log "killing apaches.."
      #child_process.exec "kill -6 `cat /var/run/apache2.pid`", ->
      #console.log arguments
      apache.kill "SIGABRT"
      ka = child_process.spawn "apache2ctl", "-k stop".split " "

      ka.stdout.on "data", (d) -> process.stdout.write d
      ka.stderr.on "data", (d) -> process.stderr.write d
      ka.on "exit", (code) -> "ka exit #{code}"
      #
    ###

#spawn "network", "ip", ["addr", "show", "eth0"]
spawn "mysqld", "/horde/start-mysql"
spawn "apached", "/horde/start-apache"
#spawn "sshd", "/usr/sbin/sshd", ["-D"]

checkMysql()
