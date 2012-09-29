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
  var feed = Conf.metadataDatabase.changes({ since: 1 });
    feed.on('change', function (change) {
      if(change.id.match(/^_design/)) return;
        Package.find(change.id, function(err, pkg){
          if(err) return;
          return pkg.index();
        })
    });
};
