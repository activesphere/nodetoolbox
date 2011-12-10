exports.print = (module = "") ->
  (err, info) ->
    if err
      console.log "Error: #{module} : #{err}"
    else
      console.log "Complete: #{module} : #{info}"