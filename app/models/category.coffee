Conf = require '../../lib/conf'
_ = require 'underscore'

Category = 
  all: (options, cb) ->
    criteria = _.extend( reduce:false , options)
    Conf.metadataDatabase.view 'categories/all', criteria, cb

module.exports = Category
