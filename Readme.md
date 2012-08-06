-----------------------------
Random stuff that i tend to use often

Conf.metadataDatabase.view('categories/all', {reduce:false}, function(err, res){console.log('got it')})


curl -XPUT 'localhost:9200/_river/registry/_meta' -d '{
    "type" : "couchdb",
    "couchdb" : {
        "host" : "localhost",
        "port" : 5984,
        "db" : "registry",
        "user": "activesphere",
        "password": "***********",
        "ignore_attachments":true,
        "filter" : null
    },
    "index" : {
        "index" : "registry",
        "type" : "registry",
        "bulk_size" : "100",
        "bulk_timeout" : "10ms"
    }
}'


curl -XGET 'http://localhost:9200/registry/_search?pretty=true' -d '
{ 
    "query" : { 
        "matchAll" : {} 
    } 
}'

curl -XGET 'http://localhost:9200/registry/_search?pretty=true' -d '
{ 
    "query" : { 
        "text" : { "description": "directories" }
    } 
}'