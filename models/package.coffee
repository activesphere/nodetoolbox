http                = require 'http'
coffeescript        = require 'coffee-script'
fs                  = require 'fs'
util                 = require 'util'
_                   = require 'underscore'
extensions          = require '../lib/extensions'
Conf                = require '../conf'
PackageMetadata     = require './package_metadata'
CategoryMap         = require './category_map'
redis               = require 'redis'
winston             = require 'winston'

redisClient         = redis.createClient Conf.redis.port, Conf.redis.host
redisClient.auth Conf.redis.auth

# packages_db = new cradle.Connection(Conf.couchdb.host, 5984, auth: Conf.couchdb.auth).database(Conf.couchdb.registry_database)
# metadata_db = new cradle.Connection(Conf.couchdb.host, 5984, auth: Conf.couchdb.auth).database(Conf.couchdb.metadata_database)

extensions.createIfNotExisting Conf.packageDatabase

Conf.packageDatabase.get '_design/recent', (err, doc) ->
  unless doc
    Conf.packageDatabase.save '_design/recent',
      created:
        map: (doc) ->
          emit(doc.time.created, 1) if doc.time and doc.time.created
          return

Conf.packageDatabase.get '_design/package', (err, doc) ->
  unless doc
    Conf.packageDatabase.save '_design/package',
      by_name:
        map: (doc) -> emit(doc._id, author: doc.author, description: doc.description, name: doc._id)


Conf.packageDatabase.get '_design/search', (err, doc) ->
  unless doc
    Conf.packageDatabase.save '_design/search',
      all:
        map: (doc) ->
          descriptionBlacklist = [ "for", "and", "in", "are", "is", "it", "do", "of", "on", "the", "to", "as" ]
          name = doc.name or doc["_id"]
          detailsFor = (doc) -> description: doc.description, author : doc.author
          if name
            if name
              names = [ name ]
              if name.indexOf("-") != -1
                name.split("-").forEach (n) ->
                  names.push n
              if name.indexOf("_") != -1
                name.split("_").forEach (n) ->
                  names.push n
              names.forEach (n) ->
                emit(n.toLowerCase(), null) if n.length > 1
            if doc.categories?
              doc.categories.forEach (category) ->
                emit(category.toLowerCase(), null)  
            if doc["dist-tags"] and doc["dist-tags"].latest? and (doc.versions[doc["dist-tags"].latest].keywords or doc.versions[doc["dist-tags"].latest].tags)
              tags = (doc.versions[doc["dist-tags"].latest].keywords or doc.versions[doc["dist-tags"].latest].tags)
              unless tags.forEach
                tags = if tags.indexOf(",") is -1 then tags.split(',') else tags.split(" ")
              tags.forEach (tag) ->
                tag.split(" ").forEach (t) ->
                  emit(t.toLowerCase(), null) if t.length > 0
            if doc.description
              doc.description.split(" ").forEach (d) ->
                d = d.toLowerCase()
                while d.indexOf(".") != -1
                  d = d.replace(".", "")
                while d.indexOf("\n") != -1
                  d = d.replace("\n", "")
                while d.indexOf("\r") != -1
                  d = d.replace("\n", "")
                while d.indexOf("`") != -1
                  d = d.replace("`", "")
                while d.indexOf("_") != -1
                  d = d.replace("_", "")
                while d.indexOf("\"") != -1
                  d = d.replace("\"", "")
                while d.indexOf("'") != -1
                  d = d.replace("'", "")
                while d.indexOf("(") != -1
                  d = d.replace("(", "")
                while d.indexOf(")") != -1
                  d = d.replace(")", "")
                while d.indexOf("[") != -1
                  d = d.replace("[", "")
                while d.indexOf("]") != -1
                  d = d.replace("]", "")
                while d.indexOf("{") != -1
                  d = d.replace("{", "")
                while d.indexOf("}") != -1
                  d = d.replace("}", "")
                while d.indexOf("*") != -1
                  d = d.replace("*", "")
                while d.indexOf("%") != -1
                  d = d.replace("%", "")
                while d.indexOf("+") != -1
                  d = d.replace("+", "")
                d = ""  if descriptionBlacklist.indexOf(d) != -1
                emit(d, null) if d.length > 1
          return


Conf.packageDatabase.get '_design/repositories', (err, doc) ->
  unless doc
    Conf.packageDatabase.save '_design/repositories',
      all:
        map: (doc) ->
          if doc.repository?
            emit(doc.repository, null)
          else
            emit('None', null)
          return
      git:
        map: (doc) ->
          if doc.repository? and doc.repository.url? and doc.repository.url.indexOf('github') isnt -1
            regex = /github.com\/(.*)\/(.*)\.git/
            match = doc.repository.url.match regex
            emit(doc['_id'], {user: match[1], repo: match[2]})
          return
      "non-git":
        map: (doc) ->
          if doc.repository? and doc.repository.type isnt 'git'
            url = doc.repository.url
            emit(doc['_id'], {repo: url})
          return

exports.fromSearch = (docs) ->
  _.map docs, (doc) ->
    id: doc.id, doc: {id: doc.id, description:doc.value?.description, author: doc.value?.author}

exports.watch_updates = () ->
  redisPosition = "6020"
  redisClient.get 'current_npm_id', (err, value) ->
    if err or parseInt(value, 10) < 6020
      value = "6020"
      redisClient.set 'current_npm_id', value, redis.print
    else
      redisPosition = value
    winston.log "setting redis current_npm_id to #{redisPosition}"    
    Conf.packageDatabase.changes(since: parseInt(redisPosition, 10) , feed: 'continuous').on 'response', (res) ->
      res.on 'data', (change) -> 
        winston.log "New change on #{util.inspect(change)}"
        Conf.packageDatabase.get change.id, (err, doc) ->
          redisClient.incr 'current_npm_id', redis.print
          if not err and doc?.keywords
            winston.log "updating changes for keywords #{doc.keywords}"
            exports.updateChanged doc
          else
            winston.log "Error in getting document for #{change._id} #{util.inspect(err)}" if err

exports.updateChanged = (doc) ->
  try
    keywords =  if _.isArray(doc.keywords) then doc.keywords else [doc.keywords]
    categories = _.map doc.keywords, (keyword) ->
      CategoryMap.from_keyword keyword
    exports.save_categories doc.id, categories, (err, doc) -> winston.log "updateChanged:docid-> #{doc._id}"
  catch error
    winston.log "updateChanged:Error #{error}"
  if doc.repository?.url
    winston.log "Repo url -> #{doc.repository.url}"
    regex = /github.com\/(.*)\/(.*)\.git/
    match = doc.repository.url.match regex
    if match and match[1] and match[2]
      PackageMetadata.createOrUpdate id: doc.id, user: match[1], repo: match[2], (err, res) ->
        if err
          winston.log "createOrUpdateError:error : #{err}"
        else
          winston.log "createOrUpdateError:response : #{response}"

exports.import_from_npm = (o, callback) ->
  couchConfig = conf.couchdb
  npmDb = new cradle.Connection(couchConfig.npm_registry.host, couchConfig.npm_registry.port).database(couchConfig.npm_registry.database)
  npmDb.replicate "http://#{couchConfig.username}:#{couchConfig.password}@#{couchConfig.host}/#{couchConfig.registry_database}", callback
  
exports.import_from_github = (o, callback) ->
  Conf.packageDatabase.view 'repositories/git', _.extend(o, include_docs: true), (err, docs) ->
    updateGithubInfo = (view_doc) ->
      PackageMetadata.createOrUpdate id: view_doc.doc['_id'], user: view_doc.value.user, repo: view_doc.value.repo, (err, res) -> winston.log( err || res)
    count = 0
    _.each docs, (view_doc) ->
      count = count + 1
      _.delay(_.bind(updateGithubInfo, {}, view_doc), 1500 * count)
    callback null, {to_import: docs.length}

exports.save_categories = (name, category_name, callback) ->
  unless name is ''
    categories = _.flatten [category_name]
    Conf.metadataDatabase.get name, (err, metaDoc) ->
      if(err)
        winston.log "creating new doc for #{name}"
        Conf.metadataDatabase.save name, categories: categories
      else
        if metaDoc['categories']?
          metaDoc['categories'] = _.union metaDoc['categories'], categories
        else
          metaDoc['categories'] = categories
        Conf.metadataDatabase.save name, metaDoc['_rev'], metaDoc, (err, res) -> 
          if err
            winston.log "save_categories: error:#{name} #{err}"
          else
            winston.log "Successfuly saved #{name} : #{res}"

exports.by_rank = (number_of_items = 10, callback) ->
  Conf.metadataDatabase.view 'categories/rank', {limit: number_of_items, descending: true}, (err, docs) ->
    callback.apply null, [docs]

exports.like = (package, user, callback) ->
  redisClient.sadd "#{package}:like", user, (err, val) ->
    redisClient.scard "#{package}:like", (err, val) ->
      callback err, val
  
exports.by_category = (category_name, top_count = 10, callback) ->
  criteria = if category_name? then {reduce:false, key: category_name} else {reduce:false}
  Conf.metadataDatabase.view 'categories/all', criteria, (err, docs) ->
    top_n = (packages) ->
      top = packages.sort (a, b) ->
        (b.forks + b.watchers) - (a.forks + a.watchers)
      top = top.slice 0, top_count
      top
    
    all_docs_for_category = {}
    for doc in docs
      do (doc) ->
        all_docs_for_category[doc.key] = [] unless all_docs_for_category[doc.key]
        all_docs_for_category[doc.key].push(doc.value)
    results = {}
    for category, packages of all_docs_for_category
      count = packages.length
      results[category] = 
        docs: top_n(packages)
        count: count
    callback.apply null, [results]

exports.find = (name, callback) ->
  winston.log " finding package #{name}"
  Conf.metadataDatabase.get name, (err, doc) ->
    if err or not doc
      callback err, null
    else
      Conf.packageDatabase.get name, (error, package) ->
        if not error and package
          _.extend package, doc
          redisClient.scard "#{name}:like", (err, reply) ->
            _.extend package, likes: reply || 0
            callback.apply null, [null, package] 
        else
          callback null, [error, null]

exports.find_all = (key, callback) ->
  key ||= 'a'  
  Conf.packageDatabase.view 'package/by_name', startkey: "#{key}aaaa", endkey: "#{key}zzzz", include_docs: false, (err, docs) ->
    callback.apply null, [ key: key, docs: exports.fromSearch(docs)]

exports.search = (query, callback) ->
  if query?.trim() isnt ''
    query = query.trim()
    Conf.packageDatabase.view "search/all", key: query, include_docs: false, (err, result) ->
      docs = _.uniq result, false, (item) -> item['id']
      PackageMetadata.rank exports.fromSearch(docs), (err, result) ->
        callback.apply null, [ 
          key: query
          result: result
      ]

exports.top_by_dependencies = (top_n = 10, callback) ->
  Conf.packageDatabase.view 'ui/dependencies', {reduce: true, group: true}, (err, results) ->
    results = results?.sort (a, b)->
      b.value - a.value
    results = results?.slice(0, top_n) || []
    callback.apply null, [results]

exports.recently_added = (number_of_recently_added = 10, callback) ->
  Conf.packageDatabase.view 'recent/created', {descending: true, limit: number_of_recently_added}, (err, results) ->
    callback.apply null, [results]

