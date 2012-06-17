Conf      = require '../../lib/conf'
extensions= require '../../lib/extensions'
logger = require 'winston'

extensions.createIfNotExisting Conf.userDatabase

exports.findOrCreate = (source, user_id, user_name, accessToken, accessTokenSecret, promise) ->
  Conf.userDatabase.view "docs/by_#{source}", key: user_id, (err, docs) ->
    if err
      logger.error "Error using users/_design/docs/_view/by_#{source} #{err.reason}"
      return promise.fail(err)

    if docs.length > 0
      user = docs[0].value
      promise.fulfill user
    else
      create (err, doc)->
        if error
          return promise.fail(error)
        promise.fulfill doc

create = (cb) ->
  doc =
    accessToken: accessToken
    name: user_name
  doc["#{source}Id"] = user_id
  Conf.userDatabase.save doc, cb
  