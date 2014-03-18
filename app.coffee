lifx = require 'lifx'
express = require 'express'

app = express()

lx = lifx.init()

DEFAULT_LENGTH = 20 * 60 * 1000

class Sunrise
  scheduleSunrise: (delta) ->
    if @next
      clearTimeout @nextId
    @next = delta + new Date()
    @nextId = setTimeout () =>
      @sunrise DEFAULT_LENGTH
    , delta

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
sun.scheduleSunrise 0

lx.on 'packet', (p) ->
  if p.packetTypeShortName == 'lightStatus'
    console.log 'lightStatus', p

