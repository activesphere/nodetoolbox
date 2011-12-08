Conf = exports = module.exports

process.env.NODE_ENV ||= "development"
process.env.ENV_VARIABLE = process.env.NODE_ENV

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
