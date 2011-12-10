coffee    = require 'coffee-script'
express   = require 'express'
cron      = require 'cron'
util       = require 'util'
winston   = require 'winston'

Conf      = require './conf'
everyauth = require('./auth').create(Conf)
helper = require './lib/helper'

packages  = require './models/package'
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
  app.use everyauth.middleware()
  app.use app.router
  app.set 'view engine', 'jade'
  app.set 'views', __dirname + '/views'
  app.use express.static __dirname + '/public'
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

app.get '/', (req, res) ->
  packages.by_category null, 10, (categories) ->
    packages.by_rank 10, (top_ranked_packages) ->
      res.render 'index', 
        categories: categories
        top_ranked_packages: top_ranked_packages
        title: 'Node.js happiness'

app.get '/packages', (req, res) ->
  packages.find_all req.query.key, (packages_info) ->
    res.render 'packages', key: packages_info.key, packages: packages_info.docs, title: 'All Packages'

app.get '/packages/:name', (req, res, next) ->
  packages.find req.params.name, (err, package) ->
    if err
      next(err)
    else
      latest_tag =  package["dist-tags"]?.latest ? ""
      latest = package.versions?[latest_tag]
      res.render 'package', package: package, title: req.params.name, latest_tag: latest_tag, latest: latest 

app.get '/categories', (req, res) ->
  packages.by_category null, 10, (categories) ->
    res.render 'categories', categories: categories, title: 'All Categories'

app.get '/categories/:name', (req, res) ->
  packages.by_category req.params.name, 10000, (category_info) ->
    res.render 'category', category_info: category_info, title: "Category - #{req.params.name}"

app.get '/search', (req, res) ->
  packages.search req.query.q, (response) ->
    res.render 'search_result', response: response, title: "Search - #{req.query.q}"

app.get '/top_dependent_packages', (req, res) ->
  packages.top_by_dependencies 10, (results) ->
    res.render 'top_by_dependencies', layout: false, results: results, title: "Top packages by dependency"

app.get '/recently_added', (req, res) ->
  packages.recently_added 10, (results) ->
    res.render 'recently_added', layout: false, results: results, title: "Recently added packages"

app.post '/packages/:name/like', (req, res, next) ->
  if req.session.auth
    packages.like req.params.name, req.session.auth.github.user.login, (err, count) ->
      res.send  count: count
  else
    res.send "Please log in to Like", 403

port = process.env.PORT || 4000

app.listen port, () ->
  winston.log "app started at port #{port}"

do packages.watch_updates

if process.env.ENV_VARIABLE is 'production'
  new cron.CronJob '0 0 4 * * * *', () ->
    winston.log "Running github sync Cron now"
    packages.import_from_github {}, helper.print("github sync")
      
  new cron.CronJob '0 0 5 * * * *', () ->
    winston.log "Running Import job Cron now"
    packages.import_from_npm {}, helper.print( "NPM Import")