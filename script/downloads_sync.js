#!/usr/bin/env node
var sync = require('../lib/downloads_sync');

var start = new Date();
console.log("Starting the sync at "+ new Date());
sync.downloads(function(err, res){
  console.log("Download Sync completed successfully");
  console.log("Ending the sync at "+ new Date());
  console.log("It took "+ (new Date() - start) + " millies");
  process.exit(0);
});
