require('coffee-script')
var Conf = require('./lib/conf')
var _ = require('underscore')
var Package = require('./app/models/package')
var e = Conf.elasticSearch


Package.search('redis-proxy', function (err, package) {
  console.log(package);
})
Package.find('redis', function (err, package) {
  console.log(package.downloads);
})

var x =e.getMapping('npm', 'package').on('data', function(data){
  
}).exec();

function search(query){
  var x = e.search('npm', 'package', query).on('data', function(data){
    console.log(data)
  }).exec();  
}


var query = {
    "query" : {
        "term" : { "name" : "d3" }
    }
};

var d3 = {
  sort : [
          { "downloads" : {"missing" : 0, "order": "desc"} },
          "github",
          { "forks_count" : {"missing" : 0, "order": "desc"} },
          { "watchers_count" : {"missing" : 0, "order": "desc"}},
          "_score"
      ],
  query: {query_string: {fields: ['name^5','_id^3', 'keywords^2', 'description'], query: "d3"}}};

var d3 = {
  sort: [{ "downloads" : {"missing" : 0, "order": "desc"} }, {"github": {"ignore_unmapped" : true}}, "_score"],
  query: {query_string: {fields: ['name^5','_id^3', 'keywords^2', 'description'], query: "d3"}}
};

search(d3)



{
    "package" : {
        "_all" : {"enabled" : true},
        "properties" : {
            "name" : {"type" : "string", "store" : "yes", "boost": 5},
            "description" : {"type" : "string", "store" : "yes"},
            "readme" : {"type" : "string", "store" : "yes"},
            "owner" : {"type" : "string", "store" : "yes"},
            "categories" : {"type" : "string", "store" : "yes"},
            "author": { 
              "properties":{
                "name": {"type" : "string", "store" : "yes"},
                "email": {"type" : "string", "store" : "yes"}
               }
            },
            "repository": { 
              "properties":{
                "type": {"type" : "string", "store" : "yes"},
                "url": {"type" : "string", "store" : "yes"}
               }
            },
            "github": { 
              "properties":{
                "forks_count": {"type" : "integer", "store" : "yes"},
                "watchers_count": {"type" : "integer", "store" : "yes"},
                "updated_at": {"type" : "date", "format" : "dateOptionalTime"},
                "created_at": {"type" : "date", "format" : "dateOptionalTime"},
                "name": {"type" : "string", "store" : "yes"},
                "homepage": {"type" : "string", "store" : "yes"}
               }
            }
        }
    }
}

curl -XPUT 'http://ec2-50-16-23-51.compute-1.amazonaws.com:9200/npm/package/_mapping' -d '
{
    "package" : {
        "_all" : {"enabled" : true},
        "properties" : {
            "name" : {"type" : "string", "store" : "yes", "boost": 5},
            "description" : {"type" : "string", "store" : "yes", "boost": 2},
            "readme" : {"type" : "string", "store" : "yes"},
            "owner" : {"type" : "string", "store" : "yes"},
            "categories" : {"type" : "string", "store" : "yes", "boost": 2},
            "author": {
              "properties":{
                "name": {"type" : "string", "store" : "yes"},
                "email": {"type" : "string", "store" : "yes"}
               }
            },
            "repository": {
              "properties":{
                "type": {"type" : "string", "store" : "yes"},
                "url": {"type" : "string", "store" : "yes"}
               }
            },
            "downloads": {"type" : "integer", "store" : "yes"},
            "github": {
              "properties":{
                "forks_count": {"type" : "integer", "store" : "yes"},
                "watchers_count": {"type" : "integer", "store" : "yes"},
                "updated_at": {"type" : "date", "format" : "dateOptionalTime", "ignore_malformed":true},
                "created_at": {"type" : "date", "format" : "dateOptionalTime", "ignore_malformed":true},
                "name": {"type" : "string", "store" : "yes"},
                "homepage": {"type" : "string", "store" : "yes"},
                "language": {"type" : "string", "store" : "yes"}
               }
            }
        }
    }
}
'



{"name":"andtan-node-hid","owner":"andtan","categories":[],"github":{"description":"Access HID devices through Node.JS","open_issues":0,"pushed_at":"2012/04/09 07:40:58 -0700","source":"hanshuebner/node-hid","homepage":"","watchers":3,"has_downloads":true,"url":"https://github.com/andtan/node-hid","fork":true,"parent":"hanshuebner/node-hid","size":124,"private":false,"name":"node-hid","owner":"andtan","has_issues":false,"has_wiki":true,"forks":0,"language":"C++","created_at":"2012/03/29 07:58:59 -0700"},"downloads":0}]}