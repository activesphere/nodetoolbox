Package  = require '../models/package'

module.exports = PackageController =
  home: (req, res) ->
    Package.by_category null, 10, (err, categories) ->
      Package.by_rank 10, (err, top_ranked_packages) ->
        res.render 'index', 
          categories: categories
          top_ranked_packages: top_ranked_packages
          title: 'Node.js happiness'
  show: (req, res) ->
    Package.find req.params.name, (err, pkg) ->
      if err
        return next(err)

      latest_tag =  pkg["dist-tags"]?.latest ? ""
      latest = pkg.versions?[latest_tag]
      res.render 'package', package: pkg, title: req.params.name, latest_tag: latest_tag, latest: latest 

  index: (req, res) ->
    Package.all req.query.key, (err, packages_info) ->
      if err
        return next(err)
      res.render 'packages', key: packages_info.key, packages: packages_info.docs, title: 'All Packages'
    
