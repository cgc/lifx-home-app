lifx = require 'lifx'
express = require 'express'

lx = lifx.init()

DEFAULT_LENGTH = 20 * 60 * 1000

bulbSet = (newBulbLum, bulbLength) ->
  lx.lightsColour(0xd49e, 0x0, newBulbLum, 0x0dac, bulbLength)

class Sunrise
  scheduleSunrise: (delta) ->
    @deleteSunriseIfExists()
    @next = new Date delta + (+new Date())
    console.log delta, new Date(), @next
    @nextId = setTimeout () =>
      @sunrise DEFAULT_LENGTH
    , delta

  deleteSunriseIfExists: () ->
    if @next
      clearTimeout @nextId
      @next = null

  sunrise: (length) ->
    @deleteSunriseIfExists()
    bulbLength = 0xfeee
    # XXX going to set to this number for now so we can see more logging.
    bulbLength = 0xfee

    bulbMaxLum = 0xffff
    elapsed = 0
    id = setInterval () ->
      if (elapsed * bulbLength) > length
        clearInterval id
        return
      # Math.floor() is necessary so that we're supplying an integer.
      newBulbLum = Math.min bulbMaxLum, Math.floor(bulbMaxLum * ((elapsed + 1) * bulbLength / length))
      console.log 'new lights colour', newBulbLum, bulbLength
      bulbSet newBulbLum, bulbLength
      elapsed++
    , bulbLength

sun = new Sunrise()

lx.on 'packet', (p) ->
  if p.packetTypeShortName == 'lightStatus'
    console.log 'lightStatus', p

configure = (app) ->
  app.get '/sunrise', (req, res, next) ->
    res.render 'sunrise', sun: sun

  app.post '/sunrise', (req, res, next) ->
    delta = parseInt req.body.delta, 10
    sun.scheduleSunrise delta
    res.redirect '/sunrise'

  app.post '/sunrise/delete', (req, res, next) ->
    sun.deleteSunriseIfExists()
    res.redirect '/sunrise'

  app.post '/mega-dim', (req, res, next) ->
    bulbSet Math.floor(0xffff / 125), 1000
    res.redirect '/sunrise'

app = express()
app.set 'views', __dirname + '/views'
app.set 'view engine', 'jade'
app.use express.bodyParser()
configure app
app.listen 2173