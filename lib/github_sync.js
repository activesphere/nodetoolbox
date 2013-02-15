require('coffee-script');
var Github = require('../app/models/github');
var Package = require('../app/models/package');
var async = require('async');
var helper = require('./helper');
var util = require('util');
var logger = require('winston');
var _ = require('underscore');

var getDataFromGithub = function(package, cb){

  logger.info("Github :"+package.id);
  async.parallel({github: getRepoInfo(package), githubUser: getUserInfo(package)}, function (err, res) {
    if(err){
      logger.info("Failed to update " + package.id);
      logger.error(err);
      return cb(null, null);
    }
    Package.updateMetadata(package.id, res, cb)
  });
};

function getRepoInfo (package) {
  return function(cb) {
    return Github.getInfo(package.value, cb);
  };
};

function getUserInfo (package) {
  return function(cb) {
    return Github.getUserInfo(package.value, cb);
  };
};

module.exports.github = function(cb){
  if(!_.isFunction(cb)){
    cb = helper.print;
  }
  Package.gitPackages(function(err, packages){
    async.forEachLimit(_.flatten([packages]), 20, _.throttle(getDataFromGithub, 1000), function(err){
      if(err){
        logger.error("Error fetching document " + util.inspect(err));
        return cb(err);
      }
      logger.info("Execution Completed successfully.");
      return cb(null,{});
    });
  });
};