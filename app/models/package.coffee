_ = require 'underscore'
Category = require './category'
Github = require './github'
User = require './user'
Conf = require '../../lib/conf'
logger = require 'winston'
async = require 'async'
util = require 'util'
helper = require '../../lib/helper'

Package = (attr = {}) ->
  this.attributes = attr
  this.github = attr.github
  this


Object.defineProperty Package.prototype, "id", get: () -> this.attributes._id
Object.defineProperty Package.prototype, "owner", {get: () -> this.github?.owner?.login || this.attributes.github.owner}
Object.defineProperty Package.prototype, "authorName", get: () -> this.attributes.author?.name or "Unknown"
Object.defineProperty Package.prototype, "authorEmail", get: () -> this.attributes.author?.email or ""
Object.defineProperty Package.prototype, "name",  get: () -> this.attributes.name or this.attributes["_id"]
Object.defineProperty Package.prototype, "repositoryName", { get: () -> this.github?.name}
Object.defineProperty Package.prototype, "latestVersion",  get: () -> this.attributes.versions[this.attributes['dist-tags']?.latest]
Object.defineProperty Package.prototype, "lastUpdatedOn",  get: () -> if this.github then new Date(this.github?.pushed_at).toISOString() else "Unknown"
Object.defineProperty Package.prototype, "homepage",  get: () -> this.latestVersion?.homepage || this.attributes.author?.url
Object.defineProperty Package.prototype, "engines",  get: () -> this.latestVersion?.engines || []
Object.defineProperty Package.prototype, "contributers",  get: () -> this.latestVersion?.contributers || []
Object.defineProperty Package.prototype, "maintainers",  get: () -> this.latestVersion?.maintainers || []
Object.defineProperty Package.prototype, "categories",  get: () -> this.attributes.categories || []
Object.defineProperty Package.prototype, "dependencies",  get: () -> this.latestVersion?.dependencies || []
Object.defineProperty Package.prototype, "devDependencies",  get: () -> this.latestVersion?.devDependencies || []
Object.defineProperty Package.prototype, "rank",  get: () -> if this.attributes.github then (this.attributes.github.forks + this.attributes.github.watchers) else 0
Object.defineProperty Package.prototype, "codeCommand",  get: () ->
  "git clone #{this.attributes.repository.url}"   if this.attributes.repository?.type == 'git' and this.attributes.repository?.url

Object.defineProperty Package.prototype, "installCommand",  get: () ->
  if this.latestVersion?.preferGlobal == true
    "npm install -g #{this.attributes['_id']}"
  else
    "npm install #{this.attributes['_id']}"


Package.watch_updates = () ->
  logger.info "Watching Updates from Couchdb"

Package.by_category = (category_name, top_count = 10, cb) ->
  opts = {include_docs: false}
  if( category_name )
    opts.key = category_name
  Category.all opts , (err, docs) ->
    if err 
      logger.error util.inspect(err)
      return cb(err)
    all_docs_for_category = {}
    _.each docs, (doc) ->
        all_docs_for_category[doc.key] = [] unless all_docs_for_category[doc.key]
        all_docs_for_category[doc.key].push(doc.value)
    results = {}

    for category, packages of all_docs_for_category
      count = packages.length
      results[category] =
        docs: _.first _.sortBy(packages, (a) -> -(a.forks + a.watchers)), top_count
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
    if error
      return cb error
    Conf.metadataDatabase.get name, (err, doc) ->
      if !err
        _.extend pkg, doc
      Conf.redisClient.scard "#{name}:like", (err, reply) ->
        _.extend pkg, likes: reply || 0
        cb null, new Package(pkg)

Package.like = (pkg, user, callback) ->
  Conf.redisClient.sadd "#{pkg}:like", user, (err, val) ->
    if err
      return callback err
    Conf.redisClient.scard "#{pkg}:like", (err, val) ->
      callback err, val

Package.fork = (pkg, userGithubId, cb) ->
  User.findByGithubId userGithubId, (err, user) ->
    Conf.metadataDatabase.get pkg, (err, pkgMeta) ->
      Github.fork(owner: pkgMeta.github.owner.login, repositoryName: pkgMeta.github.name, user, cb)

Package.watch = (pkg, userGithubId, cb) ->
  User.findByGithubId userGithubId, (err, user) ->
    Conf.metadataDatabase.get pkg, (err, pkgMeta) ->
      Github.watch( owner: pkgMeta.github.owner.login, repositoryName: pkgMeta.github.name, user, cb)

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

Package.updateMetadata = (pkg, info, cb) ->
  cb = cb || helper.print
  Conf.metadataDatabase.get pkg , (err, doc) ->
    if err
      logger.error "Document is not found #{pkg}  #{util.inspect(err)}"
      logger.info "Creating a new package..."
      Conf.metadataDatabase.save pkg, info, cb
    if doc
      data = _.extend {}, doc, info
      Conf.metadataDatabase.save pkg, doc['_rev'], data, cb

module.exports = Package