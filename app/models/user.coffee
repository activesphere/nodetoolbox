Conf      = require '../conf'
extensions= require '../lib/extensions'
winston = require 'winston'

extensions.createIfNotExisting Conf.userDatabase

exports.findOrCreate = (source, user_id, user_name, accessToken, accessTokenSecret, promise) ->
  Conf.userDatabase.view "docs/by_#{source}", key: user_id, (err, docs) ->
    if err
      winston.error "Error using users/_design/docs/_view/by_#{source} #{err.reason}"
      promise.fail err
      return
    if docs.length > 0
      user = docs[0].value
      promise.fulfill user
    else
      doc =
        accessToken: accessToken
        name: user_name
      doc["#{source}Id"] = user_id

      Conf.userDatabase.save doc, (error, res) ->
        if error
          promise.fail error
          return
        promise.fulfill doc
