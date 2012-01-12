require 'coffee-script'
redis = require 'redis'
PackageMetadata = require '../models/package_metadata'
Packages = require '../models/package'
CategoryMap = require '../models/category_map'
_ = require 'underscore'
cradle = require 'cradle'
Conf = require '../conf'
util = require 'util'
PackagesDb = Conf.packageDatabase
MetadataDb = Conf.metadataDatabase

updateCategories = (doc_id) ->
  PackagesDb.get doc_id, (err, doc) ->
    if err
      console.log "error for #{doc_id}" + util.inspect(err)
    else
      keywords = doc.keywords || doc.versions[doc['dist-tags']?.latest]?.keywords
      Packages.updateChanged(doc, keywords)

updateCategoriesInOthers = () ->
  Packages.by_category 'Other', 1500, (result) ->
    _.each result['Other'].docs, (doc) ->
      updateCategories(doc.id)

fixAllCategories = (options) ->
  MetadataDb.all options, (err, docs) ->
    if err
      console.log "error - " + util.inspect(err)
    else
      console.log docs.length
      _.each docs, (doc) ->
        Packages.save_categories doc.id, undefined

fixCategoriesUnder = (category) ->
  Packages.by_category category, 1500, (result) ->
    items_count = result[category]?.docs?.length
    if items_count isnt undefined && items_count > 0
      _.each result[category].docs, (doc) ->
        Packages.save_categories doc.id, undefined

# fixCategoriesUnder('proxy')
# fixAllCategories({})
# updateCategoriesInOthers()

# _.each ['coloured'], (doc_id) ->
#   Packages.save_categories(doc_id, ["Utilities / Tools", 'Terminal'])
