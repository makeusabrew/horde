#!/usr/bin/env coffee

child_process = require "child_process"

procs = {}
spawnedProcs = 0

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

    setTimeout checkMysql, 250

runTests = ->

  options =
    cwd: "/var/www"
    env: process.env

  args = process.argv[2..]

  spawn "zombie", "./node_modules/mocha/bin/_mocha", args, options

  procs.zombie.stdout.on "data", (data) -> process.stdout.write data

  procs.zombie.on "exit", (code) ->
    procs.mysqld.kill()
    procs.apached.kill()

#spawn "network", "ip", ["addr", "show", "eth0"]
spawn "mysqld", "/horde/start-mysql"
spawn "apached", "/horde/start-apache"
#spawn "sshd", "/usr/sbin/sshd", ["-D"]

checkMysql()
