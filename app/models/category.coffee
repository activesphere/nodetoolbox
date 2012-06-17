Conf = require '../../lib/conf'
Category = 
  all: (category_name, cb) ->
    criteria = if category_name? then {reduce:false, key: category_name} else {reduce:false}
    Conf.metadataDatabase.view 'categories/all', criteria, cb

module.exports = Category
