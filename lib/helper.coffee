logger = require 'winston'
util = require 'util'
exports.print = (module = "") ->
  (err, info) ->
    if err
      logger.error "Error: #{module} : #{util.inspect(err)}"
    else
      logger.info "Complete: #{module} : #{util.inspect(info)}"
