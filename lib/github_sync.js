require('coffee-script');
var Github = require('../app/models/github');
var Package = require('../app/models/package');
var async = require('async');
var helper = require('./helper');
var util = require('util');
var logger = require('winston');
var _ = require('underscore');

var getDataFromGithub = function(package, cb){

  logger.info("Github :", package);
  async.parallel({github: getRepoInfo(package), githubUser: getUserInfo(package)}, function (err, res) {
    if(err){
      logger.info("Failed to update " + package.id);
      logger.error(err);
      return cb(); // mark it success anyways.
    }
    return Package.updateMetadata(package.id, res, cb)
  });
};

function getRepoInfo (package) {
  return _.partial(Github.getInfo, package.value)
};

function getUserInfo (package) {
  return _.partial(Github.getUserInfo, package.value);
};

module.exports.github = function(options, cb){
  if(!_.isFunction(cb)){
    cb = helper.print;
  }
  options = _.defaults(options, {throttleTime: 5000, parallelLimit: 3});
  console.log("Options", options);
  Package.gitPackages({stale: 'ok'}, function(err, packages){

    console.log(packages);
    async.forEachLimit(_.flatten([packages]), options.parallelLimit, _.throttle(getDataFromGithub, options.throttleTime), function(err){
      if(err){
        logger.error("Error fetching document " + util.inspect(err));
        return cb(err);
      }
      logger.info("Execution Completed successfully.");
      return cb(null,{});
    });
  });
};