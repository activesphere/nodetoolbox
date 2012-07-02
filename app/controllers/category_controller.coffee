Package  = require '../models/package'
logger = require 'winston'

module.exports = CategoryController =
  index: (req, res, next) ->
    logger.info 'Invoking Category Controller Index'
    Package.by_category null, 10, (err, categories) ->
      if(err)
        logger.error err
        return next(err)
      res.render 'categories', categories: categories, title: 'All Categories'

  show: (req, res, next) ->
    logger.info "Invoking Category Controller Show : #{req.params.name}"
    Package.by_category req.params.name, 10000, (err, category_info) ->
      if(err)
        logger.error err
        return next(err)
      res.render 'category', category_info: category_info, title: "Category - #{req.params.name}"

    