winston       = require 'winston'

exports.print = (module = "") ->
  (err, info) ->
    if err
      winston.error "Error: #{module} : #{err}"
    else
      winston.info "Complete: #{module} : #{info}"