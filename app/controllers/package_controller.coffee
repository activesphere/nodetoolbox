Package  = require '../models/package'
logger = require 'winston'
util = require 'util'

module.exports = PackageController =
  home: (req, res, next) ->
    Package.by_category null, 10, (err, categories) ->
      Package.by_rank 10, (err, top_ranked_packages) ->
        res.render 'index', 
          categories: categories
          top_ranked_packages: top_ranked_packages
          title: 'Node.js happiness'
  show: (req, res, next) ->
    Package.find req.params.name, (err, pkg) ->
      if err
        return next(err)
      latest_tag =  pkg["dist-tags"]?.latest ? ""
      latest = pkg.versions?[latest_tag]
      res.render 'package', package: pkg, title: req.params.name, latest_tag: latest_tag, latest: latest 

  index: (req, res, next) ->
    Package.all req.query.key, (err, packages_info) ->
      if err
        return next(err)
      res.render 'packages', key: packages_info.key, packages: packages_info.docs, title: 'All Packages'

  top_by_dependencies: (req, res, next) ->
    Package.top_by_dependencies 10, (err, results) ->
      if err
        return next(err)
      res.render 'top_by_dependencies', layout: false, results: results, title: "Top packages by dependency"

  recently_added: (req, res, next) ->
    Package.recently_added 10, (err, results) ->
      if err
        return next(err)
      res.render 'recently_added', layout: false, results: results, title: "Recently added packages"

# This should have mapped to index, but legacy wise it's needed
  search: (req, res, next) ->
    Package.search req.query.q, (err, matches) ->
      if(err)
        return next(err)
      res.render 'search_result', response: matches, title: "Search - #{req.query.q}"
