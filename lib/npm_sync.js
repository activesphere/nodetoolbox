require('coffee-script');
var Conf = require('./conf'),
  helper = require('./helper'),
  util = require('util'),
  logger = require('winston'),
  _ = require('underscore');

module.exports.npm = function(cb){
  if(!_.isFunction(cb)){
    cb = helper.print;
  }
  couchConfig = Conf.couchdb;
  logger.debug(util.inspect(Conf.couchdb));
  logger.debug("http://"+couchConfig.username + ":" + couchConfig.password + "@" + couchConfig.host + '/' + couchConfig.registry_database);
  Conf.npmDb.replicate("http://"+couchConfig.username + ":" + couchConfig.password + "@" + couchConfig.host + '/' + couchConfig.registry_database, {}, cb);
};