Package = require './package'
logger  = require 'winston'
_       = require 'underscore'
async   = require 'async'
GithubApi = require 'github'
hub = new GithubApi( version: "3.0.0")
Github = {}

Github.info = (urls, cb) ->
  async.forEachLimit(_.flatten [urls], 20, Github.getInfo, (err) -> cb(err, {success:true}))

Github.getInfo = (item, callback) ->
  logger.info "Getting info from github for #{item.user}/#{item.repo}"
  hub.repos.get item, callback

Github.fork = (pkg, user, callback) ->
  hub.authenticate type: 'oauth', token: user.accessToken
  hub.repos.fork user: pkg.owner, repo: pkg.repositoryName, callback

Github.watch = (pkg, user, cb) ->
  hub.authenticate type: 'oauth', token: user.accessToken
  hub.repos.watch user: pkg.owner, 'repo': pkg.repositoryName, cb

module.exports = Github