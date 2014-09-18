
window.AudioContext = window.AudioContext || window.webkitAudioContext
window.requestAnimationFrame = window.requestAnimationFrame ||
  window.mozRequestAnimationFrame ||
  window.webkitRequestAnimationFrame

window.cancelAnimationFrame = window.cancelAnimationFrame ||
  window.mozCancelAnimationFrame;

context = new AudioContext()
context.listener.setPosition(0, 0, 0)
mainMix = context.createGain()
mainMix.connect context.destination

spectrum = new Spectrum(context)
mainMix.connect spectrum.analyser

playHum = () ->
  settings = {length: randomRange(5, 20), delay: randomRange(0, 3)}
  hum = new Hum(context, settings)
  hum.onendCallback = playHum

  hum.output.connect mainMix

playNoise = () ->
  settings = {length: randomRange(5, 20), delay: randomRange(0, 3)}
  noise = new Noise(context, settings)
  noise.onendCallback = playNoise
  noise.output.connect mainMix

animationLoop = () ->
  spectrum.analyse()
  requestAnimationFrame animationLoop

startSound = ->
  requestAnimationFrame animationLoop
  playNoise()
  playHum()
  playNoise()
  playHum()
  playNoise()
  document.querySelector('.play').removeEventListener 'mouseup', startSound



document.querySelector('.play').addEventListener 'mouseup', startSound
