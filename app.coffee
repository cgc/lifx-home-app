lifx = require 'lifx'
express = require 'express'

lx = lifx.init()

DEFAULT_LENGTH = 20 * 60 * 1000

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
    bulbLength = 0xfeee
    bulbMaxLum = 0xffff
    elapsed = 0
    id = setInterval () ->
      if (elapsed * bulbLength) > length
        clearInterval id
        return
      # Math.floor() is necessary so that we're supplying an integer.
      newBulLum = Math.min bulbMaxLum, Math.floor(bulbMaxLum * ((elapsed + 1) * bulbLength / length))
      console.log 'new lights colour', newBulLum, bulbLength
      lx.lightsColour(0xd49e, 0x0, newBulLum, 0x0dac, bulbLength)
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

app = express()
app.set 'views', __dirname + '/views'
app.set 'view engine', 'jade'
app.use express.bodyParser()
configure app
app.listen 2173