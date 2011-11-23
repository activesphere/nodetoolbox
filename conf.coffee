Conf = exports = module.exports

process.env.NODE_ENV ||= "development"
process.env.ENV_VARIABLE = process.env.NODE_ENV

Conf.couchdb = 
  host: process.env.npm_package_config__couchdb_host
  registry_database: process.env.npm_package_config__couchdb_registry_database
  metadata_database: process.env.npm_package_config__couchdb_metadata_database

Conf.github = 
  appId: process.env.npm_package_config__github_appId
  appSecret: process.env.npm_package_config__github_appSecret

Conf.redis = 
  host: process.env.npm_package_config__redis_host
  port: process.env.npm_package_config__redis_port
  auth: process.env.npm_package_config__redis_auth
