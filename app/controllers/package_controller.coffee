Package  = require '../models/package'
Category = require '../models/category'
_ = require 'underscore'

logger = require 'winston'
util = require 'util'

module.exports = PackageController =
  home: (req, res, next) ->
    logger.info "Home page request"
    Package.by_category null, 10, (err, categories) ->
      if err
        logger.error util.inspect(err)
        return next(err)
      Package.by_rank 10, (err, top_ranked_packages) ->
        if err
          logger.error util.inspect(err)
          return next(err)
        res.render 'index',
          categories: categories
          top_ranked_packages: top_ranked_packages
          title: 'Node.js happiness'

  show: (req, res, next) ->
    logger.info "Show Package #{req.params.name}"
    Package.find req.params.name, (err, pkg) ->
      if err
        logger.error util.inspect(err)
        return next(err)
      Category.all include_docs: false, (err, documents) ->
        res.render 'package', package: pkg, title: req.params.name, layout: 'new_layout', allCategories: _.uniq(_.pluck documents, 'key')

  index: (req, res, next) ->
    logger.info "Index Package #{req.query.key}"
    Package.all req.query.key, (err, packages_info) ->
      if err
        logger.error util.inspect(err)
        return next(err)
      res.render 'packages', key: packages_info.key, packages: packages_info.docs, title: 'All Packages'

  top_by_dependencies: (req, res, next) ->
    logger.info "Invoking Top Dependencies"
    Package.top_by_dependencies 10, (err, results) ->
      if err
        logger.error util.inspect(err)
        return next(err)
      res.render 'top_by_dependencies', layout: false, results: results, title: "Top packages by dependency"

  recently_added: (req, res, next) ->
    logger.info "Invoking Recently Added"
    Package.recently_added 10, (err, results) ->
      if err
        logger.error util.inspect(err)
        return next(err)
      res.render 'recently_added', layout: false, results: results, title: "Recently added packages"

  update : (req, res, next) ->
    if req.session.auth
      logger.info "#{req.session.auth.github.user.login} #{req.params.op} #{req.params.name}"
      if req.params.op == 'like'
        Package.like req.params.name, req.session.auth.github.user.login, (err, count) ->
          if(err)
            logger.error util.inspect(err)
            return res.send "Something bad happened", 422
          res.send  count: count
      else
        Package[req.params.op] req.params.name, req.session.auth.github.user.login, (err, pkg) ->
          if(err)
            logger.error util.inspect(err)
            # return res.send "Something bad happened", 422
            return res.send "Something bad happened", 200
          res.send  200
    else
      res.send "Please log in to Like", 403

  updateCategories : (req, res, next) ->
    logger.info "Updating categories on #{req.params.name} with #{req.body.categories}"
    Package.updateMetadata req.params.name, categories: _.flatten( [req.body.categories]), (err, document) ->
      if(err)
        logger.error util.inspect(err)
        return res.send "Something bad happened", 422
      res.send  {}

# This should have mapped to index, but legacy wise it's needed
  search: (req, res, next) ->
    logger.info "Searching for package #{req.query.q}"
    Package.search req.query.q, (err, matches) ->
      if(err)
        logger.error util.inspect(err)
        return next(err)
      res.render 'search_result', response: matches, title: "Search - #{req.query.q}"