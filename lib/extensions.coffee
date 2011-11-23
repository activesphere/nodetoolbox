exports.createIfNotExisting = (db) ->
  db.exists (err, exists) ->
    if err
      console.log "error", err
    else if exists
      console.log "database - #{db.name} already exists!"
    else
      console.log "database - #{db.name} does not exist. Creating."
      do db.create

