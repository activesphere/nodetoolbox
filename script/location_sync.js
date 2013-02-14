#!/usr/bin/env node
require('coffee-script');

var Conf = require('../lib/conf'), 
    _ = require('underscore');

var start = new Date();
console.log("Starting the sync at "+ new Date());


Conf.packageDatabase.view('ui/by_location',function  (err,values) {
  if(err){
    console.log(err);
    return process.exit(1);
  }
  _.each(values, function (item) {
    console.log(item);
  });
});