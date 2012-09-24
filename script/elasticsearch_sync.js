#!/usr/bin/env node
var es = require('../lib/elasticsearch_sync');

var start = new Date();
console.log("Starting the sync at "+ new Date());
es.elasticsearch(function(err, res){
  console.log("Npm Sync completed successfully");
  console.log("Ending the sync at "+ new Date());
  console.log("It took "+ (new Date() - start) + " millies");
  process.exit(0);
});
