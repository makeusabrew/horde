#!/usr/bin/env node
var Horde;

Horde = require("../index");

process.on("SIGINT", function() {
  console.log("\nCaught SIGINT, killing docker processes and exiting...");
  Horde.stop();
  return process.exit(0);
});

Horde.start();
