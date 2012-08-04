Conf      = require '../../lib/conf'
extensions= require '../../lib/extensions'
logger = require 'winston'
util = require 'util'
extensions.createIfNotExisting Conf.userDatabase


module.exports = User = {}

User.findOrCreate = (userId, userName, accessToken, accessTokenSecret, promise) ->
  console.log(userId)
  Conf.userDatabase.view "docs/by_github", key: userId, (err, docs) ->
    if err
      logger.error "Error using users/_design/docs/_view/by_#{source} #{err.reason}"
      return promise.fail(err)

    if docs.length > 0
      user = docs[0].value
      promise.fulfill user
    else
      create userId, userName, accessToken, (err, doc)->
        if err
          logger.error util.inspect(err)
          return promise.fail(err)
        promise.fulfill doc

User.findByName = (name, cb) ->
  Conf.userDatabase.view 'users/by_id', key: name, (err, doc) ->
    if err
      return cb(err)
    console.log(doc[0])
    cb err, doc[0].value
create = (userId, userName, accessToken,  cb) ->
  doc =
    accessToken: accessToken
    name: userName
    githubId = userId
  Conf.userDatabase.save doc, cb
  