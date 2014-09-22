window.AudioContext = window.AudioContext || window.webkitAudioContext
window.requestAnimationFrame = window.requestAnimationFrame ||
  window.mozRequestAnimationFrame ||
  window.webkitRequestAnimationFrame

window.cancelAnimationFrame = window.cancelAnimationFrame ||
  window.mozCancelAnimationFrame;

context = new AudioContext()
angular.module 'whitecaps', ['whitecaps.controllers', 'whitecaps.directives']
