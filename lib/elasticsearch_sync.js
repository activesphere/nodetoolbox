require('coffee-script');
var Github = require('../app/models/github');
var Package = require('../app/models/package');
var Conf = require('../lib/conf');
var async = require('async');
var util = require('util');
var logger = require('winston');
var _ = require('underscore');

module.exports.elasticsearch = function(cb){
  if(!_.isFunction(cb)){
    cb = helper.print;
  }
  var processChanges = function processChanges (change, done) {
    if(!change.id.match(/^_design/)){
      Package.find(change.id, function(err, pkg){
        if(err){
          return done(null)
        }
        pkg.index(function (err, argument) {
          done(err, argument);
        });
      });
    }
  }

  Conf.metadataDatabase.changes({ since: 1 }, function (err, list) {
    async.forEachLimit(list, 5, processChanges, function(result){
      console.log("done");
      cb(null, result);
    });
  });
};
