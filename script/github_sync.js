#!/usr/bin/env node
var gs = require('../lib/github_sync');

var start = new Date();
console.log("Starting the sync at "+ new Date());
gs.github(function(err, res){
  console.log("Github Sync completed successfully");
  console.log("Starting the sync at "+ new Date());
  console.log("It took "+ new Date() - start + "millies");
  process.exit(0);
});