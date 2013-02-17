logger = require 'winston'
util = require 'util'
fs = require 'fs'

module.exports = VisualizationController =
  index: (req, res, next) ->
    res.render "visualization/all", title: "Visualization"
  show: (req, res, next) ->
    logger.info "Invoking Visualization Controller Show : #{req.params.name}"
    logger.info "#{__dirname}/../views/visualization/#{req.params.name}.jade"
    fs.exists "#{__dirname}/..//views/visualization/#{req.params.name}.jade", (exists) ->
      if !exists
        return res.send(400)
      res.render "visualization/#{req.params.name}", title: "Visualization"

    