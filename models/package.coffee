coffeescript        = require 'coffee-script'
fs                  = require 'fs'
util                = require 'util'
helper              = require '../lib/helper'

_                   = require 'underscore'
extensions          = require '../lib/extensions'
Conf                = require '../conf'
PackageMetadata     = require './package_metadata'
CategoryMap         = require './category_map'

winston             = require 'winston'

extensions.createIfNotExisting Conf.packageDatabase

create_cdb_view = (view, def) ->
  console.log 'cdb: ', view, (i for i,v of def)
  Conf.packageDatabase.get view, (err, doc) ->
    unless doc
      h = {}
      for i, v of def
        h[i] = map: v
      Conf.packageDatabase.save view, h


create_cdb_view '_design/recent', created: (doc) ->
  emit(doc.time.created, 1) if doc.time?.created

create_cdb_view '_design/package', by_name: (doc) ->
  emit(doc._id, author: doc.author, description: doc.description, name:doc._id)

create_cdb_view '_design/repositories',
  all: (doc) ->
    key = if doc.repository? then doc.repository else 'None'
    emit key, null
    return                      #todo: is this needed?
  git: (doc) ->
    if doc.repository?.url?.indexOf('github') isnt -1
      match = doc.repository.url.match /github.com\/(.*)\/(.*)\.git/
      emit doc._id, {user: match[1], repo: match[2]}
    return
  'non-git': (doc) ->
    if doc.repository?.type isnt 'git'
      emit doc._id, {repo: doc.repository.url}
    return

create_cdb_view '_design/search',
  all: (doc) ->
    name = doc.name or doc._id

    return unless name

    kwds = []
    # name
    kwds = [name].concat( name.split('-').concat name.split('_') )

    # categories
    kwds = kwds.concat(doc.categories) if doc.categories

    # tags
    tags_keywords = if (ver = doc['dist-tags']?.latest)?
      arr = []
      if doc.versions[ver].keywords?.length
        arr.concat doc.versions[ver].keywords
      if doc.versions[ver].tags?.length
        arr.concat doc.versions[ver].tags
      tag.replace(/,/g, ' ').replace(/\ +/g, ' ').split(' ') for tag in arr
    kwds = kwds.concat tags_keywords

    # description
    desc = doc.description
    desc_blacklist = "for and in are is it do of on the to as".split(' ')
    replacement_lst = ". \n \r ` _ \" ' ( ) [ ] { } * % +".split(' ')
    replacement_lst = new RegExp(i, 'g') for i in replacement_lst
    desc_keywords = []
    if typeof(desc) == 'string'
      for r in replacement_lst
        desc = desc.replace r, ' '

      desc_list = desc.replace(/\ +/g, ' ').split(' ')
      desc_keywords = [k for k in desc_list if desc_blacklist.indexOf(k) isnt -1]
    kwds = kwds.concat desc_keywords

    for k in kwds
      do (k) ->
        emit(k.toLowerCase(), null) if k.length > 1

exports.fromSearch = (docs) ->
  _.map docs, (doc) ->
    id: doc.id, doc: {id: doc.id, description:doc.value?.description, author: doc.value?.author}

exports.watch_updates = () ->
  redisPosition = "6020"
  Conf.redisClient.get 'current_npm_id', (err, value) ->
    if err or parseInt(value, 10) < 6020
      value = "6020"
      Conf.redisClient.set 'current_npm_id', value, helper.print
    else
      redisPosition = value or 0
    winston.info "setting redis current_npm_id to #{redisPosition}"
    Conf.packageDatabase.changes(since: parseInt(redisPosition, 10) , feed: 'continuous').on 'response', (res) ->
      res.on 'data', (change) ->
        winston.info "New change on #{util.inspect(change)}"
        Conf.packageDatabase.get change.id, (err, doc) ->
          Conf.redisClient.incr 'current_npm_id', helper.print
          if not err and doc?.keywords
            winston.info "updating changes for keywords #{doc.keywords}"
            exports.updateChanged doc
          else
            winston.error "Error in getting document for #{change._id} #{util.inspect(err)}" if err

exports.updateChanged = (doc, keywords=undefined) ->
  try
    keywords = keywords || doc.keywords
    keywords =  if _.isArray(keywords) then keywords else [keywords]
    categories = _.map keywords, (keyword) ->
      CategoryMap.from_keyword keyword
    exports.save_categories doc.id, categories, (err, doc) -> winston.info "updateChanged:docid-> #{doc._id}"
  catch error
    winston.error "updateChanged:Error #{error}"
  if doc.repository?.url
    winston.info "Repo url -> #{doc.repository.url}"
    regex = /github.com\/(.*)\/(.*)\.git/
    match = doc.repository.url.match regex
    if match and match[1] and match[2]
      PackageMetadata.createOrUpdate id: doc.id, user: match[1], repo: match[2], (err, res) ->
        if err
          winston.error "createOrUpdateError:error : #{err}"
        else
          winston.info "createOrUpdateError:response : #{res}"

exports.import_from_npm = (o, callback) ->
  couchConfig = Conf.couchdb
  Conf.npmDb.replicate "http://#{couchConfig.username}:#{couchConfig.password}@#{couchConfig.host}/#{couchConfig.registry_database}", callback

exports.import_from_github = (o, callback) ->
  Conf.packageDatabase.view 'repositories/git', _.extend(o, include_docs: false), (err, docs) ->
    updateGithubInfo = (view_doc) ->
      PackageMetadata.createOrUpdate id: view_doc.id, user: view_doc.value.user, repo: view_doc.value.repo, (err, res) -> winston.log( err || res)
    count = 0
    _.each docs, (view_doc) ->
      count = count + 1
      _.delay(_.bind(updateGithubInfo, {}, view_doc), 2000 * count)
    callback null, {to_import: docs.length}

exports.capitaliseFirstLetter = (string) ->
  string.charAt(0).toUpperCase() + string.slice(1)

exports.capitaliseCategories = (categories) ->
  corrected_items = _.map categories, (item) ->
    if item.match(/jquery/i)
      'jQuery'
    else if item.match(/JavaScript/i)
      'Javascript'
    else
      exports.capitaliseFirstLetter(item)
  _.uniq(corrected_items)

exports.save_categories = (name, category_name, callback) ->
  unless name is ''
    categories = _.flatten [category_name]
    Conf.metadataDatabase.get name, (err, metaDoc) ->
      if(err)
        winston.info "creating new doc for #{name}"
        Conf.metadataDatabase.save name, categories: categories
      else
        if metaDoc['categories']?
          metaDoc['categories'] = _.union metaDoc['categories'], categories
        else
          metaDoc['categories'] = categories
        metaDoc['categories'] = exports.capitaliseCategories(metaDoc['categories'])
        Conf.metadataDatabase.save name, metaDoc['_rev'], metaDoc, (err, res) ->
          if err
            winston.error "save_categories: error:#{name} #{err}"
          else
            winston.info "Successfuly saved #{name} : #{util.inspect(metaDoc['categories'])}"

exports.by_rank = (number_of_items = 10, callback) ->
  Conf.metadataDatabase.view 'categories/rank', {limit: number_of_items, descending: true}, (err, docs) ->
    callback.apply null, [docs]

exports.like = (pkg, user, callback) ->
  Conf.redisClient.sadd "#{pkg}:like", user, (err, val) ->
    Conf.redisClient.scard "#{pkg}:like", (err, val) ->
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
  winston.info " finding package #{name}"
  Conf.metadataDatabase.get name, (err, doc) ->
    if err or not doc
      callback err, null
    else
      Conf.packageDatabase.get name, (error, pkg) ->
        if not error and pkg
          _.extend pkg, doc
          Conf.redisClient.scard "#{name}:like", (err, reply) ->
            _.extend pkg, likes: reply || 0
            callback.apply null, [null, pkg]
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
