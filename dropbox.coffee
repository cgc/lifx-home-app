passport = require 'passport'
DropboxStrategy = require('passport-dropbox').Strategy
config = require './config'

passport.use(new DropboxStrategy({
    consumerKey: config.dropbox.key
    consumerSecret: config.dropbox.secret
    callbackURL: config.dropbox.callbackURL + "/auth/dropbox/callback"
  },
  (token, tokenSecret, profile, done) ->
    data = {token: token, tokenSecret: tokenSecret, profile: profile}
    done null, data
));

passport.serializeUser (user, done) ->
  done null, user

passport.deserializeUser (serialized, done) ->
  done null, serialized

exports.configure = (app) ->
  app.get '/auth/dropbox', passport.authenticate('dropbox')
  app.get '/auth/dropbox/callback', passport.authenticate('dropbox', { failureRedirect: '/login' }), (req, res) ->
    res.redirect('/')
