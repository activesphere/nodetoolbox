require('coffee-script');
var Conf = require('./conf');
var helper = require('./helper');

module.exports.npm = function(){
  couchConfig = Conf.couchdb;
  console.log(Conf.couchdb);
  console.log("http://"+couchConfig.username + ":" + couchConfig.password + "@" + couchConfig.host + '/' + couchConfig.registry_database);
  Conf.npmDb.replicate("http://"+couchConfig.username + ":" + couchConfig.password + "@" + couchConfig.host + '/' + couchConfig.registry_database, {}, helper.print);
};


