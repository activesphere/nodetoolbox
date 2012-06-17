coffee    = require 'coffee-script'
express   = require 'express'
cron      = require 'cron'
util       = require 'util'
winston   = require 'winston'

Conf      = require '../lib/conf'
everyauth = require('../lib/auth').create(Conf)
helper = require '../lib/helper'

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
  app.use app.router
  app.set 'view engine', 'jade'
  app.set 'views', __dirname + '/views'
  app.use express.static __dirname + '/../public'
  app.use express.favicon('favicon.ico')
  app.helpers helpers
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
# app.get '/packages', package_controller.index
# app.get '/packages/:name', package_controller.show
# app.get '/categories', category_controller.index
# app.get '/categories/:name', category_controller.show
# app.get '/search', package_controller.search
# app.post '/packages/:name/like', package_controller.like


app.get '/top_dependent_packages', (req, res) ->
  packages.top_by_dependencies 10, (results) ->
    res.render 'top_by_dependencies', layout: false, results: results, title: "Top packages by dependency"

app.get '/recently_added', (req, res) ->
  packages.recently_added 10, (results) ->
    res.render 'recently_added', layout: false, results: results, title: "Recently added packages"



port = process.env.PORT || 4000

app.listen port, () ->
  winston.info "app started at port #{port}"

do packages.watch_updates

if process.env.ENV_VARIABLE is 'production'
  new cron.CronJob '0 0 6,18 * * * *', () ->
    winston.info "Running github sync Cron now"
    packages.import_from_github {}, helper.print("github sync")
      
  new cron.CronJob '0 0 5,17 * * * *', () ->
    winston.info "Running Import job Cron now"
    packages.import_from_npm {}, helper.print("NPM Import")