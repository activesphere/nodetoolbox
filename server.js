(function() {
  var Conf, RedisStore, app, coffee, cron, ensureAuthenticated, everyauth, express, helper, helpers, packages, port, util, winston;
  coffee = require('coffee-script');
  express = require('express');
  cron = require('cron');
  util = require('util');
  winston = require('winston');
  Conf = require('./conf');
  everyauth = require('./auth').create(Conf);
  helper = require('./lib/helper');
  packages = require('./models/package');
  RedisStore = require('connect-redis')(express);
  app = express.createServer();
  helpers = {
    toProperCase: function(str) {
      return str.replace(/\w\S*/g, function(txt) {
        return txt.charAt(0).toUpperCase() + txt.substr(1);
      });
    },
    current_user: function(req) {
      return req.session.auth.github.user;
    },
    flash: function(req) {
      return req.flash();
    }
  };
  ensureAuthenticated = function(req, res, next) {
    if (req.loggedIn) {
      return next();
    } else {
      req.flash('warning', "Please login.");
      return res.redirect('back');
    }
  };
  app.configure(function() {
    app.use(express.bodyParser());
    app.use(express.cookieParser());
    app.use(express.session({
      store: new RedisStore({
        maxAge: 24 * 60 * 60 * 1000,
        port: Conf.redis.port,
        host: Conf.redis.host,
        pass: Conf.redis.auth
      }),
      secret: "eat your dog food"
    }));
    app.use(everyauth.middleware());
    app.use(app.router);
    app.set('view engine', 'jade');
    app.set('views', __dirname + '/views');
    app.use(express.static(__dirname + '/public'));
    app.use(express.favicon('favicon.ico'));
    app.helpers(helpers);
    return everyauth.helpExpress(app);
  });
  app.configure('development', function() {
    return app.use(express.errorHandler({
      showStack: true,
      dumpExceptions: true
    }));
  });
  app.configure('production', function() {
    return app.error(function(err, req, res, next) {
      if (err.error === 'not_found') {
        return res.render('404', {
          title: '',
          params: req.params,
          layout: false
        });
      } else {
        return next(err);
      }
    });
  });
  app.get('/', function(req, res) {
    return packages.by_category(null, 10, function(categories) {
      return packages.by_rank(10, function(top_ranked_packages) {
        return res.render('index', {
          categories: categories,
          top_ranked_packages: top_ranked_packages,
          title: 'Node.js happiness'
        });
      });
    });
  });
  app.get('/packages', function(req, res) {
    return packages.find_all(req.query.key, function(packages_info) {
      return res.render('packages', {
        key: packages_info.key,
        packages: packages_info.docs,
        title: 'All Packages'
      });
    });
  });
  app.get('/packages/:name', function(req, res, next) {
    return packages.find(req.params.name, function(err, package) {
      var latest, latest_tag, _ref, _ref2, _ref3;
      if (err) {
        return next(err);
      } else {
        latest_tag = (_ref = (_ref2 = package["dist-tags"]) != null ? _ref2.latest : void 0) != null ? _ref : "";
        latest = (_ref3 = package.versions) != null ? _ref3[latest_tag] : void 0;
        return res.render('package', {
          package: package,
          title: req.params.name,
          latest_tag: latest_tag,
          latest: latest
        });
      }
    });
  });
  app.get('/categories', function(req, res) {
    return packages.by_category(null, 10, function(categories) {
      return res.render('categories', {
        categories: categories,
        title: 'All Categories'
      });
    });
  });
  app.get('/categories/:name', function(req, res) {
    return packages.by_category(req.params.name, 10000, function(category_info) {
      return res.render('category', {
        category_info: category_info,
        title: "Category - " + req.params.name
      });
    });
  });
  app.get('/search', function(req, res) {
    return packages.search(req.query.q, function(response) {
      return res.render('search_result', {
        response: response,
        title: "Search - " + req.query.q
      });
    });
  });
  app.get('/top_dependent_packages', function(req, res) {
    return packages.top_by_dependencies(10, function(results) {
      return res.render('top_by_dependencies', {
        layout: false,
        results: results,
        title: "Top packages by dependency"
      });
    });
  });
  app.get('/recently_added', function(req, res) {
    return packages.recently_added(10, function(results) {
      return res.render('recently_added', {
        layout: false,
        results: results,
        title: "Recently added packages"
      });
    });
  });
  app.post('/packages/:name/like', function(req, res, next) {
    if (req.session.auth) {
      return packages.like(req.params.name, req.session.auth.github.user.login, function(err, count) {
        return res.send({
          count: count
        });
      });
    } else {
      return res.send("Please log in to Like", 403);
    }
  });
  port = process.env.PORT || 4000;
  app.listen(port, function() {
    return winston.info("app started at port " + port);
  });
  packages.watch_updates();
  if (process.env.ENV_VARIABLE === 'production') {
    new cron.CronJob('0 0 6,18 * * * *', function() {
      winston.info("Running github sync Cron now");
      return packages.import_from_github({}, helper.print("github sync"));
    });
    new cron.CronJob('0 0 5,17 * * * *', function() {
      winston.info("Running Import job Cron now");
      return packages.import_from_npm({}, helper.print("NPM Import"));
    });
  }
}).call(this);
