Package = require './package'
logger  = require 'winston'
_       = require 'underscore'
async   = require 'async'
GithubApi = require 'github'
hub = new GithubApi( version: "3.0.0")
Github = {}

Github.info = (urls, cb) ->
  async.forEachLimit(_.flatten [urls], 20, Github.getInfo, (err) -> cb(err, {success:true}))

Github.getInfo = (item, cb) ->
  # logger.info "Getting info from github for #{item.user}/#{item.repo}"
  hub.repos.get item, cb
    

module.exports = Github