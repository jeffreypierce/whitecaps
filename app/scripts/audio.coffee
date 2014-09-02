window.AudioContext = window.AudioContext || window.webkitAudioContext

context = new AudioContext()
context.listener.setPosition(0, 0, 0)

spectrum = new Spectrum(context)

playHum = (len = 10) ->
  hum = new Hum(context, len)
  console.log hum
  hum.output.connect spectrum.analyser

playNoise = (len = 10) ->
  noise = new Noise(context, len)
  noise.output.connect spectrum.analyser

playHum()
playNoise()
