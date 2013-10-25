#!/usr/bin/env node
var Horde;

Horde = require("../index");

process.on("SIGINT", function() {
  console.log("\nCaught SIGINT, killing docker processes and exiting...");
  return Horde.stop();
});

Horde.start(process.argv);
