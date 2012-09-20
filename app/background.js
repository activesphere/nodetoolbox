require('coffee-script');
var cron = require('cron');
var logger = require('winston');
var Conf = require('../lib/conf');
var Package = require('./models/package');
var helper = require('../lib/helper');
var async = require('async');
var _ = require('underscore');

var Sync = {
  github: require('../lib/github_sync').github,
  npm   : require('../lib/npm_sync').npm
  downloads   : require('../lib/npm_sync').npm
};
module.exports.start = function(){
  new cron.CronJob( '0 0 0/3 * * *', function(){
    logger.info( "Running github sync Cron now");
    logger.info( new Date().toString());
    Sync.github();
  }).start();

  new cron.CronJob('5 5 5 * * *', function(){
    logger.info( "Running Import job Cron now");
    logger.info( new Date().toString());
    Sync.npm();
  }).start();

  new cron.CronJob('5 5 5,9,15,19,23 * * *', function(){
    logger.info( "Running Download job from Couchdb");
    logger.info( new Date().toString());
    Sync.downloads();
  }).start();
}
