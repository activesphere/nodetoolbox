["Testing / Spec Frameworks".
"TCP / IP".
"Utilities / Tools",
"Debugging / Console Utilities",
"OpenSSL / Crypto / Hashing",
"Parsers / Generators"]

require("coffee-script")
var Cat = require("./app/models/category");
var Conf = require("./lib/conf");
var under = require("underscore");
var util = require('util');

Cat.all({key: "Debugging / Console Utilities"}, function(err, matches){
  under.each(matches, function(match){
    Conf.metadataDatabase.get(match.id, function  (err, doc) {
      console.log(doc.id);
      var toReplace = under.indexOf(doc.categories, "Debugging / Console Utilities");
      if(toReplace!== -1){
        doc.categories[toReplace] = "Debugging and Console Utilities";
        Conf.metadataDatabase.merge(match.id, doc, function  (err, val) {
          if(err)
            return console.log("error happend" + util.inspect(err));
            return console.log("x");
        });        
      }
    });
  } );
})


Conf.metadataDatabase.get('yeti',  function  (err, doc) {
  var toReplace = under.indexOf(doc.categories, "Testing / Spec Frameworks");
  if(toReplace!== -1){
    doc.categories[toReplace] = "Testing";
    Conf.metadataDatabase.merge(doc.id, doc, function  (err, val) {
      if(err)
        return console.log("error happend" + err);
      return console.log("x");
    });        
  }
} ); 