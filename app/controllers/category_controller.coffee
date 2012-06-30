Package  = require '../models/package'

module.exports = CategoryController =
  index: (req, res, next) ->
    Package.by_category null, 10, (err, categories) ->
      if(err)
        return next(err)
      res.render 'categories', categories: categories, title: 'All Categories'
  show: (req, res, next) ->
    Package.by_category req.params.name, 10000, (err, category_info) ->
      if(err)
        return next(err)
      res.render 'category', category_info: category_info, title: "Category - #{req.params.name}"

    