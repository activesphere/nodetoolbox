auth    = require 'everyauth'
User    = require './models/user'

exports.create = (Conf) ->
  auth
    .github
      .appId(Conf.github.appId)
      .appSecret(Conf.github.appSecret)
      .findOrCreateUser (session, accessToken, accessTokenSecret, githubUserData) ->
        promise = @Promise()
        User.findOrCreate 'github', githubUserData.id, githubUserData.login, accessToken, accessTokenSecret, promise
        promise
      .redirectPath('/');

  return auth    
