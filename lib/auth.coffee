auth    = require 'everyauth'
User    = require '../app/models/user'
auth.debug = true
exports.create = (Conf) ->
  console.log(Conf.github)
  auth
    .github
      .apiHost('https://api.github.com')
      .appId(Conf.github.appId)
      .appSecret(Conf.github.appSecret)
      .fetchOAuthUser (accessToken)->
        p = this.Promise()
        this.oauth.get this.apiHost() + '/user', accessToken, (err, data) ->
          if (err)
            return p.fail(err)
          p.fulfill(JSON.parse(data))
        p
      .findOrCreateUser (session, accessToken, accessTokenSecret, githubUserData) ->
        promise = @Promise()
        User.findOrCreate 'github', githubUserData.id, githubUserData.login, accessToken, accessTokenSecret, promise
        promise
      .redirectPath('/');
  return auth
