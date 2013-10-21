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

    return importSchema() if ready

    setTimeout checkMysql, 250

runTests = ->
  options =
    cwd: "/var/www"
    env: process.env

  args = process.argv[2..]

  spawn "phpunit", "phpunit", args, options

  procs.phpunit.stdout.on "data", (data) -> process.stdout.write data

  procs.phpunit.on "exit", (code) ->
    procs.mysqld.kill()

spawn "mysqld", "/horde/start-mysql"

checkMysql()
