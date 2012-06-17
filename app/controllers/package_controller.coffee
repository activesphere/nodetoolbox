packages  = require '../models/package'

module.exports = PackageController =
  home: (req, res) ->
    packages.by_category null, 10, (err, categories) ->
      packages.by_rank 10, (err, top_ranked_packages) ->
        res.render 'index', 
          categories: categories
          top_ranked_packages: top_ranked_packages
          title: 'Node.js happiness'
