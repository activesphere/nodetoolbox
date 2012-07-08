require('coffee-script');
var Github = require('../app/models/github');
var Package = require('../app/models/package');
var async = require('async');
var util = require('util');
var logger = require('winston');
var _ = require('underscore');


Package.gitPackages(function(err, packages){
  async.forEachLimit(_.flatten([packages]), 20, function(package, cb){
    Github.getInfo(package.value, function(err, githubPackageInfo){
      if(err){
        logger.error("Could not find info for"+ util.inspect(package.value));
        return cb(err);
      }
      Package.updateMetadata(package, githubPackageInfo, function(err, code){
        if(err){
          return logger.error("Could not save "+ package.id + " "+ util.inspect(err));
        }
        logger.info("Updated info for "+ package.id);
      });
      cb(null, githubPackageInfo);
    });
  }, function(err){
    logger.error("Error fetching document " + util.inspect(err));
  });
});

