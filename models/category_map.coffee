_ = require 'underscore'

exports.ALL =
  "Ajax": ["ajax"]
  "API Clients": ["api", "client", "library", "api clients"]
  "Asynchronous": ["async", "asynchronous", "control flow / async goodies"]
  "Authentication": ["authentication"]
  "Backbone": ["backbone"]
  "Browser": ["browser"]
  "Build and Deployment": ["build"]
  "Cache": ["cache"]
  "Canvas": ["canvas"]
  "Class systems": ["class systems"]
  "CLI": ["cli", "command line option parsers", "command", "console"]
  "Color": ["color"]
  "CoffeeScript Modules": ["coffeescript", "coffeeScript modules", "coffee-script", "coffee"]
  "CommonJS": ["CommonJS compatible modules that can be used with node.", "commonjs"]
  "Compiler": ["compiler"]  
  "Connect": ["connect"]
  "Content Management Systems": ["content management systems"]
  "Continuous Integration Tools": ["continuous integration tools"]
  "Control Flow": ["control flow / async goodies", "flow-control", "flow", "message queues", 'async']
  "CouchDB": ["couchdb", "couch"]
  "CSS Engines": ["css"]
  "DB Misc and Cross DB": ["db misc and cross db"]
  "Database": ["data", "database"]
  "Date": ["date", "time"]
  "Debugging / Console Utilities": ["console"]
  "Distributed": ["distributed", "cluster"]
  "Documentation": ["documentation", "document"]
  "E-mail": ["email"]
  "Engine": ["engine"]
  "Ender": ["ender"]
  "Express": ["express"]
  "Events": ["event", "events", "e"]
  "Facebook": ["facebook"]
  "File System": ["fs", "file"]
  "Frameworks": ["framework", "frameworks", "mvc"]
  "Functional": ["functional"]
  "Google": ["google"]
  "Graphics": ["graphics"]
  "Hive": ["hive"]
  "HTML": ["html", "html5", "dom"]
  "HTTP": ["http", "i", "compression"]
  "I18n and L10n modules": ["i18n and l10n modules"]
  "Image": ["image"]
  "Inheritance": ["inheritance"]
  "Javascript": ["javascript", "jsdom", "JavaScript"]
  "jQuery": ["jquery", "JQuery"]
  "JSON": ["json"]
  "Language": ["language"]
  "Logging": ["log", "logging"]
  "Middleware": ["middleware"]    
  "Markdown": ["markdown"]
  "Microframeworks": ["microframeworks"]
  "Modules": ["modules"]
  "MongoDB": ["mongodb", "mongo", "mongoose", "Mongo"]
  "MVC Framework": ["mvc", "MVC"]
  "MySQL": ["mysql"]
  "NoSQL": ["nosql", "nosql misc"]
  "OpenSSL / Crypto / Hashing": ["openssl / crypto / hashing"]
  "ORM": ["orm"]
  "Parsers / Generators": ["parser", "parsers", "parser generators", "other parsers", "generator", "parse"]
  "Package Management Systems": ["package management systems"]
  "Payment Gateways": ["payment gateways"]
  "Project Generators": ["project generators"]
  "Proxy": ["proxy"]
  "Queue": ["queue"]
  "Realtime": ["realtime"]
  "Require": ["require"]
  "Restful": ["rest", "restful"]
  "Redis": ["redis"]
  "Routers": ["routers"]
  "RPC": ["rpc"]
  "Search": ["search"]
  "Server": ["server"]
  "SMTP": ["smtp"]
  "Socket": ["socket", "socket.io",  "websocket"]
  "Static": ["static"]
  "Static file servers": ["static file servers"]
  "Stream": ["stream"]
  "Testing / Spec Frameworks": ["tdd", "bdd", "spec", "unit", "test", "tests", "testing"]
  "TCP / IP": ["tcp / ip"]
  "Terminal": ["terminal"]
  "Templating": ["template", "templating"]
  "Time": ["time"]
  "Twitter": ["twitter"]
  "Underscore": ["underscore"]
  "Utilities / Tools": ["utils", "util", "utility", "tools", "node management utilities", "node", "nodejs"]
  "Web": ["web"]
  "Widgets": ["widget", "widgets"]
  "Web Sockets & Ajax": ["web sockets & ajax"]
  "Wrapper": ["wrapper"]
  "XML": ["xml", "Xml"]
  "YUI": ["yui", "yui2", "yui3"]

exports.from_keyword = (keyword) ->
  keys = _.keys exports.ALL
  _.filter keys, (key) -> _.include exports.ALL[key], keyword.toLowerCase()