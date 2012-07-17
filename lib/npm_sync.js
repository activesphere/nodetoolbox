require('coffee-script');
var Conf = require('./conf'),
  helper = require('./helper'),
  _ = require('underscore');

module.exports.npm = function(cb){
  if(!_.isFunction(cb)){
    cb = helper.print;
  }
  couchConfig = Conf.couchdb;
  console.log(Conf.couchdb);
  console.log("http://"+couchConfig.username + ":" + couchConfig.password + "@" + couchConfig.host + '/' + couchConfig.registry_database);
  Conf.npmDb.replicate("http://"+couchConfig.username + ":" + couchConfig.password + "@" + couchConfig.host + '/' + couchConfig.registry_database, {}, cb);
};