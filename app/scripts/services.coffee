services = angular.module 'whitecaps.services', []

services.factory 'settingsService', () ->
  {
    'noiseSettings':
      'attack':
        minValue: 10
        maxValue: 70
        scale: [0, 100]
      'length':
        minValue: 5
        maxValue: 30
        scale: [3, 40]
      'shape':
        minValue: 500
        maxValue: 3000
        scale: [0, 5000]
      'motion':
        minValue: -60
        maxValue: 75
        scale: [-90, 90]

    'humSettings':
      'attack':
        minValue: 10
        maxValue: 50
        scale: [0, 100]
      'length':
        minValue: 10
        maxValue: 20
        scale: [3, 30]
      'shape':
        minValue: 500
        maxValue: 3000
        scale: [0, 5000]
      'motion':
        minValue: -45
        maxValue: 87
        scale: [-90, 90]

    'frequencies':
      'low': [82.4, 110, 123.46, 130.81]

    'reverbSettings':
      'amount': 45
      'roomSize': 80

  }

services.factory 'mobileService', () ->
  isMobile = false
  ua = navigator.userAgent
  matchers = [
    /iPhone/i,
    /iPod/i,
    /iPad/i,
    /(?=.*\bAndroid\b)(?=.*\bMobile\b)/i,
    /Android/i
  ]
  
  _.each matchers, (match) ->
    isMobile = true if match.test ua

  {
    isMobile: isMobile
  }
