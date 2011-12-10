cradle = require 'sreeix-cradle'
redis  = require 'redis'

Conf = exports = module.exports

process.env.NODE_ENV ||= "development"
process.env.ENV_VARIABLE = process.env.NODE_ENV

# Should deprecate this stufff
Conf.couchdb = 
  host: process.env.npm_package_config__couchdb_host
  registry_database: process.env.npm_package_config__couchdb_registry_database
  metadata_database: process.env.npm_package_config__couchdb_metadata_database
  username: process.env.npm_package_config__couchdb_username
  password: process.env.npm_package_config__couchdb_password
  npm_registry: 
    host : "isaacs.iriscouch.com"
    port : 5984
    database : "registry"
Conf.github =
  appId: process.env.npm_package_config__github_appId
  appSecret: process.env.npm_package_config__github_appSecret

Conf.redis =
  host: process.env.npm_package_config__redis_host
  port: process.env.npm_package_config__redis_port
  auth: process.env.npm_package_config__redis_auth


Conf.packageDatabase = new cradle.Connection(Conf.couchdb.host, 5984, auth: Conf.couchdb.auth).database(Conf.couchdb.registry_database)
Conf.metadataDatabase = new cradle.Connection(Conf.couchdb.host, 5984, auth: Conf.couchdb.auth).database(Conf.couchdb.metadata_database)
Conf.userDatabase = new cradle.Connection(Conf.couchdb.host, 5984, auth: Conf.couchdb.auth).database("users")
Conf.redisClient =  redis.createClient Conf.redis.port, Conf.redis.host
Conf.redisClient.auth Conf.redis.auth
