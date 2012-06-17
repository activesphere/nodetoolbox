Package  = require '../models/package'

module.exports = CategoryController =
  index: (req, res) ->
    Package.by_category null, 10, (err, categories) ->
      res.render 'categories', categories: categories, title: 'All Categories'