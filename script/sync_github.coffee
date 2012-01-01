require 'coffee-script'
redis = require 'redis'
PackageMetadata = require '../models/package_metadata'
_ = require 'underscore'
cradle = require 'cradle'
Conf = require '../conf'
sys = require 'sys'
redisClient = Conf.redisClient

args = process.argv
console.log "args - #{sys.inspect(args)}"

updateDocumentsInfo = () ->
redisClient.lrange 'toolbox:github_repos', 0, -1, (err, elements) ->
  packages = _.map elements, (json) -> 
    JSON.parse json
  packages = _.shuffle packages  
  updateGithubInfo = (module) -> 
    console.log module.repo
    PackageMetadata.createOrUpdate module, (err, res) -> 
      if err
        console.log "error happened #{sys.inspect(err)}"
        if err.status == 404 
          redisClient.lrem 'toolbox:github_repos', 0, JSON.stringify(module)
          redisClient.sadd 'toolbox:github_repos:404', "#{module.user}/module.repo"
        if err.status == 401
          redisClient.lrem 'toolbox:github_repos', 0, JSON.stringify(module)
          redisClient.sadd 'toolbox:github_repos:401', "#{module.user}/module.repo"
        if err.status == 403
          console.log 'Got errors on rate limit, trying in 5 minutes'
      else
        console.log(res)
        redisClient.lrem 'toolbox:github_repos', 0, JSON.stringify(module)
        redisClient.llen 'toolbox:github_repos', (err, count) -> console.log "current count #{count}"
  count = 0  
  _.each packages, (item) ->
    count = count + 1
    _.delay(_.bind(updateGithubInfo, {}, item), 1000 * count)

if args[2] == 'setup'
  packagesDb = Conf.packageDatabase
  metadataDb = Conf.metadataDatabase
  console.log 'Querying for the data'
  o = {}
  packagesDb.view 'repositories/git', _.extend(o, include_docs: false), (err, docs) ->
    console.log err
    for view_doc in docs
      do (view_doc) ->
        console.log "saving . #{sys.inspect(view_doc)}"
        redisClient.lpush 'toolbox:github_repos', JSON.stringify(id: view_doc.id, user: view_doc.value.user, repo: view_doc.value.repo), (err, res) -> console.log(res)
else
    updateDocumentsInfo
