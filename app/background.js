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
  npm   : require('../lib/npm_sync').npm,
  downloads   : require('../lib/downloads_sync').downloads
};

module.exports.start = function(){
  logger.info("Setting up the cron jobs");
  new cron.CronJob( '0 0 7 * * *', function(){
    logger.info( "Running github sync Cron now");
    logger.info( new Date().toString());
    Sync.github({throttleTime: 10000, parallel: 5});
  }).start();

  // new cron.CronJob('5 5 5 * * *', function(){
  //   logger.info( "Running Import job Cron now");
  //   logger.info( new Date().toString());
  //   Sync.npm();
  // }).start();
  //
  // new cron.CronJob('5 5 4 * * *', function(){
  //   logger.info( "Running Download job from Couchdb");
  //   logger.info( new Date().toString());
  //   Sync.downloads();
  // }).start();
  logger.info("Done.");

}
