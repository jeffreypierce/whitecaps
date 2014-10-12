services = angular.module 'whitecaps.services', []

services.factory 'settingsService', () ->
  {
    noiseSettings:
      'amount':
        minValue: 10
        maxValue: 70
        scale: [0, 100]
      'length':
        minValue: 5
        maxValue: 20
        scale: [3, 30]
      'shape':
        minValue: 500
        maxValue: 3000
        scale: [0, 5000]
      'motion':
        minValue: -75
        maxValue: 80
        scale: [-90, 90]

    humSettings:
      'amount':
        minValue: 10
        maxValue: 70
        scale: [0, 100]
      'length':
        minValue: 5
        maxValue: 20
        scale: [3, 30]
      'shape':
        minValue: 500
        maxValue: 3000
        scale: [0, 5000]
      'motion':
        minValue: -75
        maxValue: 80
        scale: [-90, 90]

    frequencies: [82.4, 110, 123.46, 130.81]

  }
