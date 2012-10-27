require 'coffee-script'
express   = require 'express'
util      = require 'util'
logger    = require 'winston'
fs        = require 'fs'

Conf      = require '../lib/conf'
everyauth = require('../lib/auth').create(Conf)
helper    = require '../lib/helper'

package_controller = require './controllers/package_controller'
category_controller = require './controllers/category_controller'
packages = require './models/package'
RedisStore = require('connect-redis')(express)
app = express.createServer()

helpers = 
  toProperCase: (str) ->
    str.replace ///\w\S*///g, (txt) -> 
      txt.charAt(0).toUpperCase() + txt.substr(1)
  current_user: (req) ->
    req.session.auth.github.user
  flash: (req) ->
    req.flash()
  timeago: require 'timeago'
  production: () ->
    process.env.NODE_ENV == 'production'

ensureAuthenticated = (req, res, next) ->
  if req.loggedIn
    next()
  else
    req.flash('warning', "Please login.")
    res.redirect('back');

app.configure ->
  app.use express.bodyParser()
  app.use express.cookieParser()

  app.use express.session 
    store: new RedisStore
      maxAge: 24 * 60 * 60 * 1000
      port: Conf.redis.port
      host: Conf.redis.host
      pass: Conf.redis.auth
    secret: "eat your dog food"

  app.set 'view engine', 'jade'
  app.set 'views', __dirname + '/views'
  app.use express.static __dirname + '/../public'
  app.use express.favicon('favicon.ico')
  app.helpers helpers
  app.use app.router

  app.use everyauth.middleware()

  everyauth.helpExpress(app)

app.configure 'development', () ->
  app.use express.errorHandler(showStack: true, dumpExceptions: true)

app.configure 'production', () ->
  app.error (err, req, res, next) ->
    if err.error is 'not_found'
      res.render '404', title: '', params: req.params, layout: false
    else
      next(err)

app.get '/', package_controller.home
app.get '/packages', package_controller.index
app.get '/packages/:name', package_controller.show
app.get '/categories', category_controller.index
app.get '/categories/:name', category_controller.show
app.get '/search', package_controller.search
app.post '/packages/:name/:op', package_controller.update
app.post '/packages/:name', package_controller.updateCategories


app.get '/top_dependent_packages', package_controller.top_by_dependencies
app.get '/recently_added', package_controller.recently_added
app.get '/top_downloads', package_controller.top_by_downloads

port = process.env.PORT || 4000
if process.env.PIDFILE
  fs.writeFile process.env.PIDFILE, process.pid, (err) ->
    if (err)
      throw err
console.log "----------------------------------------------"
console.log process.env.NODE_ENV
console.log process.env.npm_config_production
console.log "----------------------------------------------"
app.listen port, () ->
  logger.info "Node Version is #{process.version}"
  logger.info "app started at port #{port}"
  logger.info "The time now is " + new Date().toString()

if Conf.isBackground()
  logger.info "This is a background box. starting the background processes."
  background = require './background'
  background.start()
