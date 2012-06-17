logger       = require 'winston'

exports.print = (module = "") ->
  (err, info) ->
    if err
      logger.error "Error: #{module} : #{err}"
    else
      logger.info "Complete: #{module} : #{info}"
