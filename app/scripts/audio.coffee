window.AudioContext = window.AudioContext || window.webkitAudioContext

window.requestAnimationFrame = window.requestAnimationFrame ||
  window.mozRequestAnimationFrame ||
  window.webkitRequestAnimationFrame

window.cancelAnimationFrame = window.cancelAnimationFrame ||
  window.mozCancelAnimationFrame

context = new AudioContext()
spectrum = new Spectrum(context)
mainMix = context.createGain()

mainMix.connect spectrum.analyser
mainMix.connect context.destination
