cradle    = require 'cradle'
Conf      = require '../conf'
extensions= require '../lib/extensions'
users_db  = new cradle.Connection(Conf.couchdb.host, 5984, auth: Conf.couchdb.auth).database("users")

extensions.createIfNotExisting users_db

users_db.get '_design/docs', (err, res) ->
  if err
    users_db.save('_design/docs'
      , views:
          by_github:
            map: "function(doc) { if (doc.githubId) emit(doc.githubId, doc); }"
      , (err, res) ->
        console.log "error in creating views for user #{err.reason}" if err
    )

exports.findOrCreate = (source, user_id, user_name, accessToken, accessTokenSecret, promise) ->
  users_db.view "docs/by_#{source}", key: user_id, (err, docs) ->
    if err
      console.log "Error using users/_design/docs/_view/by_#{source} #{err.reason}"
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

      users_db.save doc, (error, res) ->
        if error
          promise.fail error
          return
        promise.fulfill doc
