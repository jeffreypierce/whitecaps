controllers = angular.module('whitecaps.controllers', [])

controllers.controller 'container', ($scope) ->
  containerNode = angular.element('.container')
  sections = ['home', 'noise', 'hum']
  position = 0
  $scope.currentSection = sections[position]

  updateSection = (pos) ->
    position = pos
    $scope.currentSection = sections[position % sections.length]
    $scope.$apply()

  angular.element('.title-bar__next').on 'click', () ->
    updateSection(position += 1)

  angular.element('.title-bar__prev').on 'click', () ->
    updateSection(position -= 1)

  angular.element('nav li').on 'click', (e) ->
    pos = sections.indexOf this.className
    updateSection pos
  $scope.active = ''
  $scope.setActive = (name) ->
    $scope.active = name


controllers.controller 'home', ($scope) ->
  context.listener.setPosition(0, 0, 0)
  mainMix = context.createGain()
  mainMix.connect context.destination

  spectrum = new Spectrum(context)
  mainMix.connect spectrum.analyser

  playHum = () ->
    settings = {length: randomRange(5, 20), delay: randomRange(0, 3)}
    hum = new Hum(settings)
    hum.onendCallback = playHum
    hum.output.connect mainMix

  playNoise = () ->
    settings = {length: randomRange(5, 20), delay: randomRange(0, 3)}
    noise = new Noise(settings)
    noise.onendCallback = playNoise
    noise.output.connect mainMix

  animationLoop = () ->
    spectrum.analyse()
    requestAnimationFrame animationLoop

  startSound = ->
    requestAnimationFrame animationLoop
    playNoise()
    playNoise()
    playNoise()
    angular.element('.play').off 'mouseup', startSound

  angular.element('.play').on 'mouseup', startSound

controllers.controller 'noise', ($scope)->
  $scope.bars = [
    {
      name: 'amount'
      minValue: 10
      maxValue: 70
      scale: [0, 100]
    }
    {
      name: 'shape'
      minValue: 40
      maxValue: 61
      scale: [0, 100]
    }
    {
      name: 'growth'
      minValue: 0
      maxValue: 100
      scale: [0, 100]
    }
    {
      name: 'motion'
      minValue: 2000
      maxValue: 3000
      scale: [1000, 4000]
    }
  ]


controllers.controller 'hum', ($scope)->

  $scope.bars = [
    {
      name: 'amount'
      minValue: 10
      maxValue: 70
      scale: [0, 100]
    }
    {
      name: 'shape'
      minValue: 40
      maxValue: 61
      scale: [0, 100]
    }
    {
      name: 'growth'
      minValue: 0
      maxValue: 100
      scale: [0, 100]
    }
    {
      name: 'motion'
      minValue: 2000
      maxValue: 3000
      scale: [1000, 4000]
    }
  ]
