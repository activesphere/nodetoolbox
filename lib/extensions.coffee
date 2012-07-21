logger = require 'winston'
util = require 'util'

exports.createIfNotExisting = (db) ->
  db.exists (err, exists) ->
    if err
      logger.error "createIfNotExisting:error", util.inspect(err)
    else if exists
      logger.debug "createIfNotExisting:database - #{db.name} already exists!"
    else
      logger.debug "createIfNotExisting:database - #{db.name} does not exist. Creating."
      db.create()
