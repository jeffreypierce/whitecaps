
window.AudioContext = window.AudioContext || window.webkitAudioContext

window.requestAnimationFrame = window.requestAnimationFrame ||
  window.mozRequestAnimationFrame ||
  window.webkitRequestAnimationFrame

window.cancelAnimationFrame = window.cancelAnimationFrame ||
  window.mozCancelAnimationFrame


window.context = new AudioContext()
window.spectrum = new Spectrum(context)
window.mainMix = context.createGain()

mainMix.connect spectrum.analyser
mainMix.connect context.destination
