controllers = angular.module('whitecaps.controllers', [])

controllers.controller 'white', ($scope)->
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
