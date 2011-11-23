http                = require 'http'
coffeescript        = require 'coffee-script'
fs                  = require 'fs'
sys                 = require 'sys'
cradle              = require 'cradle'
_                   = require 'underscore'
extensions          = require '../lib/extensions'
Conf                = require '../conf'
PackageMetadata     = require './package_metadata'
CategoryMap         = require './category_map'
redis               = require 'redis'
redisClient         = redis.createClient Conf.redis.port, Conf.redis.host
redisClient.auth Conf.redis.auth

packages_db = new cradle.Connection(Conf.couchdb.host, 5984, auth: Conf.couchdb.auth).database(Conf.couchdb.registry_database)
metadata_db = new cradle.Connection(Conf.couchdb.host, 5984, auth: Conf.couchdb.auth).database(Conf.couchdb.metadata_database)

extensions.createIfNotExisting packages_db


packages_db.get '_design/recent', (err, doc) ->
  unless doc
    packages_db.save '_design/recent',
      created:
        map: (doc) ->
          emit(doc.time.created, 1) if doc.time and doc.time.created
          return

packages_db.get '_design/search', (err, doc) ->
  unless doc
    packages_db.save '_design/search',
      all:
        map: (doc) ->
          descriptionBlacklist = [ "for", "and", "in", "are", "is", "it", "do", "of", "on", "the", "to", "as" ]
          name = doc.name or doc["_id"]
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


packages_db.get '_design/repositories', (err, doc) ->
  unless doc
    packages_db.save '_design/repositories',
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

exports.watch_updates = () ->
  redisPosition = "6020"
  redisClient.get 'current_npm_id', (err, value) ->
    if err or parseInt(value, 10) < 6020
      value = "6020"
      redisClient.set 'current_npm_id', value, redis.print
    else
      redisPosition = value

    packages_db.changes(since: parseInt(redisPosition, 10) , feed: 'continuous').on 'response', (res) ->
      res.on 'data', (change) -> 
        packages_db.get change.id, (err, doc) ->
          redisClient.incr 'current_npm_id', redis.print
          if not err and doc?.keywords
            exports.updateChanged doc
          else
            console.log "Error in getting document for #{change._id} #{sys.inspect(err)}" if err

exports.updateChanged = (doc) ->
  try
    keywords =  if _.isArray(doc.keywords) then doc.keywords else [doc.keywords]
    categories = _.map doc.keywords, (keyword) ->
      CategoryMap.from_keyword keyword
    exports.save_categories doc.id, categories, (err, doc) -> console.log doc._id
  catch error
    console.log error
  if doc.repository?.url
    console.log doc.repository.url
    regex = /github.com\/(.*)\/(.*)\.git/
    match = doc.repository.url.match regex
    if match and match[1] and match[2]
      PackageMetadata.createOrUpdate id: doc.id, user: match[1], repo: match[2], (err, res) ->
        console.log( err || res)

exports.import_from_github = (o, callback) ->
  packages_db.view 'repositories/git', _.extend(o, include_docs: true), (err, docs) ->
    updateGithubInfo = (view_doc) ->
      PackageMetadata.createOrUpdate id: view_doc.doc['_id'], user: view_doc.value.user, repo: view_doc.value.repo, (err, res) -> console.log( err || res)
    count = 0
    _.each docs, (view_doc) ->
      count = count + 1
      _.delay(_.bind(updateGithubInfo, {}, view_doc), 2000 * count)
    callback.apply null, [{to_import: docs.length}]

exports.save_categories = (name, category_name, callback) ->
  unless name is ''
    categories = _.flatten [category_name]
    metadata_db.get name, (err, metaDoc) ->
      if(err)
        console.log "creating new doc for #{name}"
        metadata_db.save name, categories: categories
      else
        if metaDoc['categories']?
          metaDoc['categories'] = _.union metaDoc['categories'], categories
        else
          metaDoc['categories'] = categories
        metadata_db.save name, metaDoc['_rev'], metaDoc, (err, res) -> 
          console.log(err|| res)

exports.by_rank = (number_of_items = 10, callback) ->
  metadata_db.view 'categories/rank', {limit: number_of_items, descending: true}, (err, docs) ->
    callback.apply null, [docs]

exports.like = (package, user, callback) ->
  redisClient.sadd "#{package}:like", user, (err, val) ->
    redisClient.scard "#{package}:like", (err, val) ->
      callback err, val
  
exports.by_category = (category_name, top_count = 10, callback) ->
  criteria = if category_name? then {reduce:false, key: category_name} else {reduce:false}
  metadata_db.view 'categories/all', criteria, (err, docs) ->
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
  console.log " finding package #{name}"
  metadata_db.get name, (err, doc) ->
    if err or not doc
      callback err, null
    else
      packages_db.get name, (error, package) ->
        if not error and package
          _.extend(package, doc)
          redisClient.scard "#{name}:like", (err, reply) ->
            _.extend package, likes: reply
            callback.apply null, [null, package] 
        else
          callback(error, null)

exports.find_all = (key, callback) ->
  key ||= 'a'  
  startkey = "\"#{key}aaaa\""
  endkey = "\"#{key}zzzz\""
  packages_db.all {startkey: startkey, endkey: endkey, include_docs: true}, (err, docs) ->
    console.log err.reason if err
    callback.apply null, [{key: key, docs: docs}]

exports.search = (query, callback) ->
  if query? and query.trim() isnt ''
    query = query.trim()
    packages_db.view "search/all", {key: query, include_docs: true}, (err, result) ->
      callback.apply null, [{key: query, result: _.uniq(result, false, (item) -> item['id'])}]

exports.top_by_dependencies = (top_n = 10, callback) ->
  packages_db.view 'ui/dependencies', {reduce: true, group: true}, (err, results) ->
    results = results?.sort (a, b)->
      b.value - a.value
    results = results?.slice(0, top_n) || []
    callback.apply null, [results]

exports.recently_added = (number_of_recently_added = 10, callback) ->
  packages_db.view 'recent/created', {descending: true, limit: number_of_recently_added}, (err, results) ->
    callback.apply null, [results]

