Conf      = require '../conf'
extensions= require '../lib/extensions'

extensions.createIfNotExisting Conf.userDatabase

Conf.userDatabase.get '_design/docs', (err, res) ->
  if err
    Conf.userDatabase.save('_design/docs'
      , views:
          by_github:
            map: "function(doc) { if (doc.githubId) emit(doc.githubId, doc); }"
      , (err, res) ->
        winston.error "error in creating views for user #{err.reason}" if err
    )

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
