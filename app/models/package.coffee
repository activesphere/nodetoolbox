_ = require 'underscore'
Category = require './category'
Conf = require '../../lib/conf'
logger = require 'winston'
async = require 'async'
util = require 'util'
helper = require '../../lib/helper'

Package = {}

Package.watch_updates = () ->
  logger.info "Watching Updates from Couchdb"

Package.by_category = (category_name, top_count = 10, cb) ->
  Category.all category_name, (err, docs) ->
    if err 
      logger.error err
      return cb(err)
    all_docs_for_category = {}
    _.each docs, (doc) ->
        all_docs_for_category[doc.key] = [] unless all_docs_for_category[doc.key]
        all_docs_for_category[doc.key].push(doc.value)
    results = {}

    for category, packages of all_docs_for_category
      count = packages.length
      results[category] = 
        docs: _.first _.sortBy(packages, (a, b) ->  (b.forks + b.watchers) - (a.forks + a.watchers)), top_count
        count: count
    cb null, results

Package.by_rank = (number_of_items = 10, cb) ->
  Conf.metadataDatabase.view 'categories/rank', {limit: number_of_items, descending: true}, (err, docs) ->
    if err
      cb err
    cb null, docs

Package.all = (filter = '', cb) ->
  filter ||= 'a'  
  Conf.packageDatabase.view 'package/by_name', startkey: "#{filter}aaaa", endkey: "#{filter}zzzz", include_docs: false, (err, docs) ->
    if err
      return cb  err
    documents = _.map docs, (doc) ->  id: doc.id, doc: {id: doc.id, description: doc.value?.description, author: doc.value?.author}  
    cb null,  key: filter, docs: documents

Package.top_by_dependencies = (count= 10, cb) ->
  Conf.packageDatabase.view 'ui/dependencies', {reduce: true, group: true}, (err, results) ->
    if(err)
      return cb(err)
    results = results?.sort (a, b) -> b.value - a.value
    cb null, _.first(results, count)

Package.recently_added = (count = 10, cb) ->
  Conf.packageDatabase.view 'recent/created', {descending: true, limit: count}, (err, results) ->
    if(err)
      return cb err
    cb null, results

Package.find = (name, cb) ->
  Conf.packageDatabase.get name, (error, pkg) ->
    console.log name
    if error
      return cb error
    Conf.metadataDatabase.get name, (err, doc) ->
      if !err
        _.extend pkg, doc
      Conf.redisClient.scard "#{name}:like", (err, reply) ->
        _.extend pkg, likes: reply || 0
        cb null, pkg

Package.like = (package, user, callback) ->
  Conf.redisClient.sadd "#{package}:like", user, (err, val) ->
    if err
      return callback err
    Conf.redisClient.scard "#{package}:like", (err, val) ->
      callback err, val

Package.search = (query, callback) ->
  if query?.trim() isnt ''
    query = query.trim()
    Conf.packageDatabase.view "search/all", key: query, include_docs: false, (err, result) ->
      docs = _.uniq result, false, (item) -> item['id']
      docs = _.map docs, (doc) -> id: doc.id, doc: {id: doc.id, description: doc.value?.description, author: doc.value?.author}
      async.sortBy(docs, (doc, cb) ->
        Conf.metadataDatabase.get doc.id, (err, doc) ->
          if doc?.github
            cb err, -(doc.github.watchers + doc.github.forks)
          else
            cb(null, 0)
      , (err, results) ->
        if err
          callback err
        callback null, {key:query, result: results}
        )

Package.gitPackages = (cb) ->
  Conf.packageDatabase.view 'repositories/git', include_docs: false, cb

Package.updateMetadata = (package, info, cb) ->
  if not cb
    cb = helper.print
  Conf.metadataDatabase.get package.id , (err, doc) ->
    if err
      logger.error "Document is not found #{package.id}  #{utils.inspect(err)}"
      logger.info "Creating a new package..."
      Conf.metadataDatabase.save package.id, github: info, cb
    if doc
      data = {}
      _.extend data, doc, github: info
      Conf.metadataDatabase.save package.id, doc['_rev'], data, cb
  

module.exports = Package