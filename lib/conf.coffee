cradle = require 'sreeix-cradle'
redis  = require 'redis'
ElasticSearchClient = require 'elasticsearchclient'


process.env.NODE_ENV ||= "development"
process.env.ENV_VARIABLE = process.env.NODE_ENV

Conf = exports = module.exports

# Should deprecate this stufff
Conf.couchdb = 
  host: process.env.npm_package_config__couchdb_host
  registry_database: process.env.npm_package_config__couchdb_registry_database
  metadata_database: process.env.npm_package_config__couchdb_metadata_database
  downloads_database: process.env.npm_package_config_couchdb_downloads_database
  auth:
    username: process.env.npm_package_config__couchdb_username
    password: process.env.npm_package_config__couchdb_password
  npm_registry: 
    host : "isaacs.iriscouch.com"
    port : 5984
    database : "registry"

Conf.github =
  appId: process.env.npm_package_config__github_appId
  appSecret: process.env.npm_package_config__github_appSecret
  appToken: process.env.npm_package_config__github_appToken

Conf.redis =
  host: process.env.npm_package_config__redis_host
  port: process.env.npm_package_config__redis_port
  auth: process.env.npm_package_config__redis_auth

Conf.elasticsearchServers =
  host: process.env.npm_package_config_elastic_server || "localhost"
  port: process.env.npm_package_config_elastic_server_port || 9200
  
Conf.elasticSearch = new ElasticSearchClient Conf.elasticsearchServers

Conf.packageDatabase = new cradle.Connection(Conf.couchdb.host, 5984, auth: Conf.couchdb.auth).database(Conf.couchdb.registry_database)
Conf.metadataDatabase = new cradle.Connection(Conf.couchdb.host, 5984, auth: Conf.couchdb.auth).database(Conf.couchdb.metadata_database)
Conf.userDatabase = new cradle.Connection(Conf.couchdb.host, 5984, auth: Conf.couchdb.auth).database("users")
Conf.npmDb = new cradle.Connection(Conf.couchdb.npm_registry.host, Conf.couchdb.npm_registry.port).database(Conf.couchdb.npm_registry.database)
Conf.downloadsDatabase = new cradle.Connection(Conf.couchdb.host, 5984, auth: Conf.couchdb.auth).database(Conf.couchdb.downloads_database)

Conf.redisClient =  redis.createClient Conf.redis.port, Conf.redis.host
Conf.redisClient.auth Conf.redis.auth
Conf.isBackground = () ->
  process.env.npm_package_config_run_background_tasks is 'true' || false

Conf.searchQuery = (query) ->
  return {
    size: 100,
    sort: [{ "downloads" : {"missing" : 0, "order": "desc"} }, {"github": {"ignore_unmapped" : true}}, "_score"],
    query: {query_string: {fields: ['name^5','_id^3', 'keywords^2', 'description^2', 'categories^2', 'readme', 'author'], query: query}}
  }