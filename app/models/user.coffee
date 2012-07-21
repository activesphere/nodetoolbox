Conf      = require '../../lib/conf'
extensions= require '../../lib/extensions'
logger = require 'winston'
util = require 'util'
extensions.createIfNotExisting Conf.userDatabase

exports.findOrCreate = (source, userId, userName, accessToken, accessTokenSecret, promise) ->
  Conf.userDatabase.view "docs/by_#{source}", key: userId, (err, docs) ->
    if err
      logger.error "Error using users/_design/docs/_view/by_#{source} #{err.reason}"
      return promise.fail(err)

    if docs.length > 0
      user = docs[0].value
      promise.fulfill user
    else
      create source, userId, userName, accessToken, (err, doc)->
        if err
          logger.error util.inspect(err)
          return promise.fail(err)
        promise.fulfill doc

create = (source, userId, userName, accessToken,  cb) ->
  doc =
    accessToken: accessToken
    name: userName
  doc["#{source}Id"] = userName
  Conf.userDatabase.save doc, cb
  