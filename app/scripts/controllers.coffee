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



controllers.controller 'home', ($scope) ->

controllers.controller 'noise', ($scope)->
  $scope.active = ''
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

  $scope.setActive = (name) ->
    $scope.active = name

controllers.controller 'hum', ($scope)->
  $scope.active = ''
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

  $scope.setActive = (name) ->
    $scope.active = name
