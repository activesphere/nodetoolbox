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
};
module.exports.start = function(){
  new cron.CronJob( '0 0 6,18 * * * *', function(){
    logger.info( "Running github sync Cron now");
    Sync.github();
  });

  new cron.CronJob('0 0 5,17 * * * *', function(){
    logger.info( "Running Import job Cron now");
    Sync.npm();
  });
}
