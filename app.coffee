lifx = require 'lifx'
express = require 'express'
socketio = require 'socket.io'
_ = require 'underscore'

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

change = (data) ->
  conv = (n, ur) -> Math.min(0xffff, Math.floor((0xffff / ur) * n))
  lx.lightsColour(conv(data.hsb.h, 360), conv(data.hsb.s, 100), conv(data.hsb.b, 100), 0x0dac, 50)
change = _.throttle change, 80

io = socketio.listen 2174
io.sockets.on 'connection', (socket) ->
  socket.on 'color:change', change

app.set 'views', __dirname + '/views'
app.set 'view engine', 'jade'
app.use express.static __dirname + '/assets'
app.use express.bodyParser()
configure app
app.listen 2173
