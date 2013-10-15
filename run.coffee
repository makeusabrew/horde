#!/usr/bin/env coffee

child_process = require "child_process"

procs = []

spawn = (name, cmd, params = [], options) ->
  proc = child_process.spawn cmd, params, options

  proc.stdout.on "data", (data) -> process.stdout.write "[#{name}] #{data}"
  proc.stderr.on "data", (data) -> process.stderr.write "[#{name}] #{data}"

  procs.push proc

  return proc

#spawn "network", "ip", ["addr", "show", "eth0"]
spawn "mysqld", "/usr/bin/mysqld_safe"
spawn "apached", "/etc/apache2/start.sh"
spawn "sshd", "/usr/sbin/sshd", ["-D"]

setTimeout ->
  runTests()
, 2000

runTests = ->
  options =
    cwd: "/var/www"
    env: process.env

  args = process.argv[2..]
  proc = spawn "zombie", "./node_modules/mocha/bin/_mocha", args, options

  proc.on "exit", (code) ->
    process.stdout.write "[zombie] process exited with code #{code} - exiting in parent"
    process.exit code
