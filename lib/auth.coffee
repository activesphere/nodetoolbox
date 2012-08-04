auth    = require 'everyauth'
User    = require '../app/models/user'
logger  = require 'winston'
util    = require 'util'
auth.debug = false

exports.create = (Conf) ->
  logger.debug util.inspect(Conf.github)
  auth
    .github
      .apiHost('https://api.github.com')
      .appId(Conf.github.appId)
      .appSecret(Conf.github.appSecret)
      .scope('repo,public_repo')
      .fetchOAuthUser (accessToken) ->
        p = this.Promise()
        this.oauth.get this.apiHost() + '/user', accessToken, (err, data) ->
          if (err)
            return p.fail(err)
          p.fulfill(JSON.parse(data))
        p
      .findOrCreateUser (session, accessToken, accessTokenSecret, githubUserData) ->
        promise = @Promise()
        User.findOrCreate githubUserData.id, githubUserData.login, accessToken, accessTokenSecret, promise
        promise
      .sendResponse (res, data)->
        this.redirect(res, data.req.headers.referer || "/")
  return auth
