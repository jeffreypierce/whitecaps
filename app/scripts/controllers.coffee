controllers = angular.module 'whitecaps.controllers', ['whitecaps.services']

controllers.controller 'container', ($scope) ->
  containerNode = angular.element('.container')
  sections = ['home', 'noise', 'hum', 'effects', 'about']
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


controllers.controller 'home', ($scope, settingsService, mobileService) ->
  $scope.noiseOn = false
  $scope.humOn = false
  $scope.options = [
    {id: 1, name: '1'}
    {id: 2, name: '2'}
    {id: 3, name: '3'}
    {id: 4, name: '4'}
    {id: 5, name: '5'}
  ]

  $scope.numOfHums = $scope.options[1]
  $scope.numOfNoises = $scope.options[2]

  if mobileService.isMobile
    $scope.numOfHums = $scope.options[0]
    $scope.numOfNoises = $scope.options[0]


  playHum = () ->
    play = ->
      settings = _.extend({} ,settingsService.frequencies, settingsService.humSettings, settingsService.reverbSettings)
      hum = new Hum settings
      hum.onendCallback = play
      hum.output.connect mainMix
    i = 0
    while i < $scope.numOfHums.id
      play()
      i++

  playNoise = ->
    play = ->
      settings = _.extend({}, settingsService.humSettings, settingsService.reverbSettings)
      noise = new Noise settings
      noise.onendCallback = play
      noise.output.connect mainMix
    i = 0
    while i < $scope.numOfNoises.id
      play()
      i++

  animationLoop = ->
    spectrum.analyse()
    requestAnimationFrame animationLoop

  requestAnimationFrame animationLoop

  stopHum = ->
    _.each hums, (hum) ->
      try
        hum.onendCallback = ->
        hum.soundSource.stop(context.currentTime)
      catch e
        window.location.reload() # hack for safari's weirdness with errors

  stopNoise = ->
    _.each noises, (noise) ->
      try
        noise.onendCallback = ->
        noise.soundSource.stop(context.currentTime)
      catch e
        window.location.reload() # hack for safari's weirdness with errors


  $scope.humControl = ->
    if $scope.humOn
      playHum()
    else
      stopHum()

  $scope.noiseControl = ->
    if $scope.noiseOn
      playNoise()
    else
      stopNoise()

controllers.controller 'noise', ($scope, settingsService) ->
  $scope.noises = settingsService.noiseSettings

controllers.controller 'hum', ($scope, settingsService)->
  $scope.hums = settingsService.humSettings

controllers.controller 'effects', ($scope, settingsService) ->
  $scope.reverb = settingsService.reverbSettings

controllers.controller 'about', ($scope)->
