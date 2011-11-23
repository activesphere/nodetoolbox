cradle    = require 'cradle'
util      = require 'util'
_      = require 'underscore'
extensions      = require '../lib/extensions'
Conf      = require '../conf'
GitHubApi   = require("github").GitHubApi
github      = new GitHubApi(true)

PackageMetadata = exports = module.exports
metadataDb = new cradle.Connection(Conf.couchdb.host, 5984, auth: Conf.couchdb.auth).database(Conf.couchdb.metadata_database)
extensions.createIfNotExisting metadataDb

metadataDb.get '_design/categories', (err, doc) ->
  unless doc
    metadataDb.save '_design/categories',
      all:
        map: (doc) ->
          if doc.github?
            obj = id: doc["_id"]
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



PackageMetadata.createOrUpdate = (opts, callback) ->
  if not callback 
    callback = (err, res)-> console.log(err || res)
  github.getRepoApi().show opts.user, opts.repo, (err, github_info) ->
    if err or !github_info
      console.log "error during fetch of the github info for #{opts.repo}, #{util.inspect(err)}"
      callback.apply null, [err, null]
    else
      console.log "Saving new document for #{opts.id}"
      metadataDb.get opts.id , (err, doc) ->
        if doc
          data = {}
          _.extend data, doc, github: github_info
          metadataDb.save opts.id, doc['_rev'], data, (err, res) ->
            console.log "update doc #{res}"
            callback.apply null, [err, res]
        else
          metadataDb.save opts.id, github: github_info, (err, res) ->
            console.log "new doc #{res}"
            callback.apply null, [err, res]
