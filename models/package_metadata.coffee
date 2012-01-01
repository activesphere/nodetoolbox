util          = require 'util'
_             = require 'underscore'
async         = require 'async'
extensions    = require '../lib/extensions'
Conf          = require '../conf'
GitHubApi     = require("github").GitHubApi
github        = new GitHubApi true
winston       = require 'winston'

PackageMetadata = exports = module.exports
extensions.createIfNotExisting Conf.metadataDatabase

Conf.metadataDatabase.get '_design/categories', (err, doc) ->
  unless doc
    Conf.metadataDatabase.save '_design/categories',
      all:
        map: (doc) ->
          if doc.github?
            obj = id: doc["_id"]
              url: doc.github.url
              forks: doc.github.forks
              watchers: doc.github.watchers
              description: doc.description
            if doc.categories?
              emit(category, obj) for category in doc.categories
            else
              emit('Other', obj)
          return
        reduce: "_count"
      rank:
        map: (doc) ->
          if doc.github?
            rank = doc.github.forks + doc.github.watchers
            emit rank, doc.description
          else
            emit -1, doc.description
          return 

PackageMetadata.rank = (docs, callback) ->
  async.sortBy(docs, (doc, call) ->
    Conf.metadataDatabase.get doc.id, (err, doc) ->
      if doc?.github
        call err, -(doc.github.watchers + doc.github.forks)
      else
        call(null, 0)
  , (err, results) -> callback(err, results))

PackageMetadata.createOrUpdate = (opts, callback) ->
  if not callback 
    callback = (err, res)-> winston.log(err || res)
  github.getRepoApi().show opts.user, opts.repo, (err, github_info) ->
    if err or !github_info
      winston.log "error during fetch of the github info for #{opts.repo}, #{util.inspect(err)}"
      callback.apply null, [err, null]
    else
      winston.log "Saving new document for #{opts.id}"
      Conf.metadataDatabase.get opts.id , (err, doc) ->
        if doc
          data = {}
          _.extend data, doc, github: github_info
          Conf.metadataDatabase.save opts.id, doc['_rev'], data, (err, res) ->
            winston.log "update doc #{res}"
            callback.apply null, [err, res]
        else
          Conf.metadataDatabase.save opts.id, github: github_info, (err, res) ->
            winston.log "new doc #{res}"
            callback.apply null, [err, res]
