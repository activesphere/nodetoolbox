require('coffee-script');
var Conf = require('./conf'),
  helper = require('./helper'),
  util = require('util'),
  logger = require('winston'),
  async = require('async'),
  _ = require('underscore');

  var formatDate = function formatDate(d) {
    var month = d.getMonth(), date = d.getDate()-1, year = d.getFullYear();
    month++;
    if(month< 10) month = "0"+ month
    if(date< 10) date = "0"+ date
    return year+ "-" + month + "-" + date;
  }

  var addItemStats = function addItemStats(item, cb){
    var name = item.key[0];
    Conf.redisClient.zadd("downloads:totals", item.value, name);

    Conf.downloadsDatabase.view ('app/pkg', {key: [name, formatDate(new Date())], reduce: true, group_level: 2}, function (err, results){
      if(err){
        console.log(err);
        return cb(err);
      }
      if( results.length === 1){
        Conf.redisClient.zadd("downloads:today", results[0].value, name, function(err, res){
          return cb(err,res);
        });
      } else{
        cb(null, []);
      }
    });
  };

  module.exports.downloads = function(cb){
    if(!_.isFunction(cb)){
      cb = helper.print;
    }
    Conf.downloadsDatabase.view ('app/pkg', {reduce: true, group_level: 1}, function (err, val){
      if(err) return cb(err);
      return async.forEach(_.first(val, val.length), addItemStats, function(err){cb(null, [])});
    });
  };