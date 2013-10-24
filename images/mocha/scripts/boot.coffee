#!/usr/bin/env coffee

child_process = require "child_process"
fs            = require "fs"

procs = {}
spawnedProcs = 0

message = (str) ->
  console.log JSON.stringify ["message", str]

spawn = (name, cmd, params = [], options) ->
  proc = child_process.spawn cmd, params, options

  spawnedProcs += 1

  procs[name] = proc

  proc.stderr.on "data", (data) -> process.stderr.write "[#{name}] #{data}"

  proc.on "exit", (code) ->

    spawnedProcs -= 1
    process.exit 0 if spawnedProcs is 0

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
  spawn "runner", "./node_modules/mocha/bin/_mocha", args, options

  procs.runner.stdout.on "data", (data) -> process.stdout.write data

  procs.runner.on "exit", (code) ->
    procs.mysqld.kill()
    procs.apached.kill()

#spawn "network", "ip", ["addr", "show", "eth0"]
spawn "mysqld", "/horde/start-mysql"
spawn "apached", "/horde/start-apache"
#spawn "sshd", "/usr/sbin/sshd", ["-D"]

checkMysql()
