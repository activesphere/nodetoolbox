exports.createIfNotExisting = (db) ->
  db.exists (err, exists) ->
    if err
      console.log "createIfNotExisting:error", err
    else if exists
      console.log "createIfNotExisting:database - #{db.name} already exists!"
    else
      console.log "createIfNotExisting:database - #{db.name} does not exist. Creating."
      do db.create

