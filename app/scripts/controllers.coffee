controllers = angular.module 'whitecaps.controllers', ['whitecaps.services']

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


controllers.controller 'home', ($scope, settingsService) ->
  $scope.isPlaying = false
  numberOfNotes = 2
  numberOfNoises = 3

  playHum = () ->
    hum = new Hum settingsService.humSettings, settingsService.frequencies
    hum.onendCallback = playHum
    hum.output.connect mainMix

  playNoise = () ->
    noise = new Noise settingsService.noiseSettings
    noise.onendCallback = playNoise
    noise.output.connect mainMix

  animationLoop = () ->
    spectrum.analyse()
    requestAnimationFrame animationLoop

  startSound = ->
    requestAnimationFrame animationLoop
    i = 0
    j = 0
    while i < numberOfNoises
      playNoise()
      i++
    while j < numberOfNotes
      playHum()
      j++

  stopSound = ->
    _.each noises, (noise) ->
      noise.onendCallback = () ->
      noise.soundSource.stop()

    _.each notes, (noise) ->
      noise.onendCallback = () ->
      noise.soundSource.stop()

  $scope.soundControl = () ->
    if $scope.isPlaying
      startSound()
    else
      stopSound()

controllers.controller 'noise', ($scope, settingsService) ->
  $scope.noises = settingsService.noiseSettings

controllers.controller 'hum', ($scope, settingsService)->
  $scope.hums = settingsService.humSettings
