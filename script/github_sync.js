#!/usr/bin/env node
var gs = require('../lib/github_sync');

var start = new Date();
console.log("Starting the sync at "+ new Date());
gs.github(function(err, res){
  if(err){
    console.log("Synch failed to complete");
    console.log(err);
    process.exit(1);
  }else {
    console.log("Github Sync completed successfully");
    console.log("Ending the sync at "+ new Date());
    console.log("It took "+ (new Date() - start) + " millies");
    process.exit(0);
  }
});