winston       = require 'winston'

exports.createIfNotExisting = (db) ->
  db.exists (err, exists) ->
    if err
      winston.error "createIfNotExisting:error", err
    else if exists
      winston.debug "createIfNotExisting:database - #{db.name} already exists!"
    else
      winston.debug "createIfNotExisting:database - #{db.name} does not exist. Creating."
      do db.create
