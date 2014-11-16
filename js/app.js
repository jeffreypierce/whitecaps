(function() {
  var Hum, Noise, Spectrum, Whitecap, canvas, canvasContext, controllers, directives, generateImpulse, generateNoiseBuffer, hums, noises, randomRange, services,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  canvas = document.querySelector("canvas");

  canvasContext = canvas.getContext("2d");

  Spectrum = (function() {
    function Spectrum(context) {
      this.analyser = context.createAnalyser();
      this.barWidth = 24;
      this.barSpacing = -12;
    }

    Spectrum.prototype.analyse = function() {
      var alpha, barCount, barHeight, frequencyData, height, i, loopStep, width, _results;
      width = canvas.width;
      height = canvas.height;
      frequencyData = new Uint8Array(this.analyser.frequencyBinCount);
      frequencyData = frequencyData.subarray(100, 400);
      this.analyser.getByteFrequencyData(frequencyData);
      canvasContext.clearRect(0, 0, width, height);
      barCount = Math.round(width / (this.barWidth + this.barSpacing));
      loopStep = Math.floor(frequencyData.length / barCount);
      i = 0;
      _results = [];
      while (i < barCount) {
        barHeight = frequencyData[i * loopStep] * (height / 255);
        alpha = barHeight / width;
        canvasContext.fillStyle = "rgba(235,239,240," + alpha + ")";
        canvasContext.fillRect(((this.barWidth + this.barSpacing) * i) + (this.barSpacing / 2), height, this.barWidth - this.barSpacing, -barHeight);
        _results.push(i++);
      }
      return _results;
    };

    return Spectrum;

  })();

  window.AudioContext = window.AudioContext || window.webkitAudioContext;

  window.requestAnimationFrame = window.requestAnimationFrame || window.mozRequestAnimationFrame || window.webkitRequestAnimationFrame;

  window.cancelAnimationFrame = window.cancelAnimationFrame || window.mozCancelAnimationFrame;

  window.context = new AudioContext();

  window.spectrum = new Spectrum(context);

  window.mainMix = context.createGain();

  mainMix.connect(spectrum.analyser);

  mainMix.connect(context.destination);

  Whitecap = (function() {
    function Whitecap(settings) {
      this.noteEnded = __bind(this.noteEnded, this);
      var dry, reverb, reverbBuffer, wet;
      this.settings = settings;
      this.delay = randomRange(settings.length.minValue, settings.length.maxValue) / 10;
      this.vol = this.settings.attack.maxValue / 100;
      this.filter = context.createBiquadFilter();
      this.adsr = context.createGain();
      this.panner = context.createPanner();
      this.output = context.createGain();
      wet = context.createGain();
      dry = context.createGain();
      reverb = context.createConvolver();
      reverbBuffer = generateImpulse(this.settings.amount / 25, this.settings.roomSize);
      reverb.buffer = reverbBuffer;
      if (this.type === 'hum') {
        this.output.gain.value = this.vol / 3;
        hums.push(this);
      }
      if (this.type === 'noise') {
        this.output.gain.value = this.vol;
        noises.push(this);
      }
      this.panner.setPosition(0, 0, 1);
      this.panner.panningModel = 'equalpower';
      this.soundSource.connect(reverb);
      this.soundSource.connect(dry);
      reverb.connect(wet);
      wet.gain.value = 0.8;
      dry.gain.value = 0.5;
      dry.connect(this.filter);
      this.filter.connect(this.adsr);
      this.adsr.connect(this.panner);
      this.panner.connect(this.output);
      this.begin = context.currentTime + this.delay;
      this.end = this.begin + this.length;
      this.soundSource.start(this.begin);
      this.soundSource.stop(this.end);
      this.automateFilter();
      this.automateVolume();
      this.automatePanning();
      this.soundSource.onended = _.debounce(this.noteEnded, 1000);
      this.onendCallback = function() {};
    }

    Whitecap.prototype.automateFilter = function() {
      var attack, attackTime, decay, decayTime;
      attackTime = (this.end - this.begin) * randomRange(10, 50) / 100 + this.begin;
      decayTime = (this.end - this.begin) * randomRange(50, 80) / 100 + this.begin;
      attack = {
        cutoff: randomRange(this.settings.shape.minValue, this.settings.shape.maxValue),
        Q: randomRange(1, 6)
      };
      decay = {
        cutoff: randomRange(this.settings.shape.minValue, this.settings.shape.maxValue),
        Q: randomRange(1, 6)
      };
      this.filter.frequency.setValueAtTime(this.settings.shape.minValue, this.begin);
      this.filter.frequency.linearRampToValueAtTime(attack.cutoff, attackTime);
      this.filter.frequency.linearRampToValueAtTime(decay.cutoff, decayTime);
      this.filter.frequency.linearRampToValueAtTime(this.settings.shape.minValue, this.end);
      this.filter.Q.setValueAtTime(5, this.begin);
      this.filter.Q.linearRampToValueAtTime(attack.Q, attackTime);
      this.filter.Q.linearRampToValueAtTime(decay.Q, decayTime);
      return this.filter.Q.linearRampToValueAtTime(1, this.end);
    };

    Whitecap.prototype.automateVolume = function() {
      var attackGain, attackTime, decayGain, decayTime;
      attackTime = (this.end - this.begin) * randomRange(10, 50) / 100 + this.begin;
      decayTime = (this.end - this.begin) * randomRange(50, 80) / 100 + this.begin;
      attackGain = randomRange(this.settings.attack.minValue, this.settings.attack.maxValue) / 100;
      decayGain = randomRange(this.settings.attack.minValue, this.settings.attack.maxValue) / 100;
      this.adsr.gain.setValueAtTime(0, this.begin);
      this.adsr.gain.linearRampToValueAtTime(attackGain, attackTime);
      this.adsr.gain.linearRampToValueAtTime(decayGain, decayTime);
      return this.adsr.gain.linearRampToValueAtTime(0, this.end);
    };

    Whitecap.prototype.automatePanning = function() {
      var distance, endPan, incrementPan, interval, startPan;
      startPan = randomRange(this.settings.motion.minValue, this.settings.motion.maxValue);
      endPan = randomRange(this.settings.motion.minValue, this.settings.motion.maxValue);
      distance = Math.abs(startPan - endPan);
      incrementPan = (function(_this) {
        return function() {
          var num, x, xDeg, z, zDeg;
          if (startPan < endPan) {
            num = startPan += 1;
            if (num > endPan - 1) {
              clearInterval(interval);
            }
          } else {
            num = startPan -= 1;
            if (num < endPan + 1) {
              clearInterval(interval);
            }
          }
          xDeg = parseInt(num);
          zDeg = xDeg + 90;
          if (zDeg > 90) {
            zDeg = 180 - zDeg;
          }
          x = Math.sin(xDeg * (Math.PI / 180));
          z = Math.sin(zDeg * (Math.PI / 180));
          return _this.panner.setPosition(x, 0, z);
        };
      })(this);
      return interval = setInterval(incrementPan, this.length * 1000 / distance);
    };

    Whitecap.prototype.noteEnded = function(e) {
      if (this.type === "hum") {
        hums.shift();
      }
      if (this.type === "noise") {
        noises.shift();
      }
      return this.onendCallback();
    };

    return Whitecap;

  })();

  Noise = (function(_super) {
    __extends(Noise, _super);

    function Noise(settings) {
      var colors;
      this.type = 'noise';
      this.soundSource = context.createBufferSource();
      this.length = randomRange(settings.length.minValue, settings.length.maxValue);
      colors = ['white', 'brown', 'pink'];
      this.soundSource.buffer = generateNoiseBuffer(this.length, colors[randomRange(0, 2)]);
      Noise.__super__.constructor.apply(this, arguments);
    }

    return Noise;

  })(Whitecap);

  Hum = (function(_super) {
    __extends(Hum, _super);

    function Hum(settings) {
      this.type = 'hum';
      this.length = randomRange(settings.length.minValue, settings.length.maxValue);
      this.soundSource = context.createOscillator();
      this.soundSource.type = 'triangle';
      Hum.__super__.constructor.apply(this, arguments);
      this.automateFrequeny(settings.low);
    }

    Hum.prototype.automateFrequeny = function(freqs) {
      var freq;
      freq = freqs[randomRange(0, freqs.length - 1)];
      this.soundSource.frequency.setValueAtTime(freq, this.begin);
      this.soundSource.frequency.linearRampToValueAtTime(freq + randomRange(-5, 5), this.begin + randomRange(1, this.length - 1));
      return this.soundSource.frequency.linearRampToValueAtTime(freq, this.end);
    };

    return Hum;

  })(Whitecap);

  randomRange = function(min, max) {
    return ~~(Math.random() * (max - min + 1)) + min;
  };

  generateImpulse = function(length, decay) {
    var i, impulse, impulseChannel, rate, _length;
    if (length == null) {
      length = 2;
    }
    if (decay == null) {
      decay = 50;
    }
    rate = context.sampleRate;
    _length = rate * length;
    impulse = context.createBuffer(1, _length, rate);
    impulseChannel = impulse.getChannelData(0);
    i = 0;
    while (i < length) {
      impulseChannel[i] = (2 * Math.random() - 1) * Math.pow(1 - i / length, decay);
      i++;
    }
    return impulse;
  };

  generateNoiseBuffer = function(length, color) {
    var arrayBuffer, audioBuffer, b0, b1, b2, b3, b4, b5, b6, i, lastOut, white, _length, _white;
    _length = context.sampleRate * length;
    arrayBuffer = new Float32Array(_length);
    white = function() {
      return 2 * Math.random() - 1;
    };
    i = 0;
    switch (color) {
      case "white":
        while (i < _length) {
          arrayBuffer[i] = white();
          i++;
        }
        break;
      case 'pink':
        b0 = b1 = b2 = b3 = b4 = b5 = b6 = 0.0;
        while (i < _length) {
          _white = white();
          b0 = 0.99886 * b0 + _white * 0.0555179;
          b1 = 0.99332 * b1 + _white * 0.0750759;
          b2 = 0.96900 * b2 + _white * 0.1538520;
          b3 = 0.86650 * b3 + _white * 0.3104856;
          b4 = 0.55000 * b4 + _white * 0.5329522;
          b5 = -0.7616 * b5 - _white * 0.0168980;
          arrayBuffer[i] = b0 + b1 + b2 + b3 + b4 + b5 + b6 + _white * 0.5362;
          arrayBuffer[i] *= 0.11;
          b6 = _white * 0.115926;
          i++;
        }
        break;
      case 'brown':
        lastOut = 0.0;
        while (i < _length) {
          arrayBuffer[i] = (lastOut + (0.02 * white())) / 1.02;
          lastOut = arrayBuffer[i];
          arrayBuffer[i] *= 3.5;
          i++;
        }
    }
    audioBuffer = context.createBuffer(1, _length, context.sampleRate);
    audioBuffer.getChannelData(0).set(arrayBuffer);
    return audioBuffer;
  };

  hums = [];

  noises = [];

  angular.module('whitecaps', ['whitecaps.controllers', 'whitecaps.directives', 'whitecaps.services']);

  controllers = angular.module('whitecaps.controllers', ['whitecaps.services']);

  controllers.controller('container', function($scope) {
    var containerNode, position, sections, updateSection;
    containerNode = angular.element('.container');
    sections = ['home', 'noise', 'hum', 'effects', 'about'];
    position = 0;
    $scope.currentSection = sections[position];
    updateSection = function(pos) {
      position = pos;
      $scope.currentSection = sections[position % sections.length];
      return $scope.$apply();
    };
    angular.element('.title-bar__next').on('click', function() {
      return updateSection(position += 1);
    });
    angular.element('.title-bar__prev').on('click', function() {
      return updateSection(position -= 1);
    });
    angular.element('nav li').on('click', function(e) {
      var pos;
      pos = sections.indexOf(this.className);
      return updateSection(pos);
    });
    $scope.active = '';
    return $scope.setActive = function(name) {
      return $scope.active = name;
    };
  });

  controllers.controller('home', function($scope, settingsService, mobileService) {
    var animationLoop, playHum, playNoise, stopHum, stopNoise;
    $scope.noiseOn = false;
    $scope.humOn = false;
    $scope.options = [
      {
        id: 1,
        name: '1'
      }, {
        id: 2,
        name: '2'
      }, {
        id: 3,
        name: '3'
      }, {
        id: 4,
        name: '4'
      }, {
        id: 5,
        name: '5'
      }
    ];
    $scope.numOfHums = $scope.options[1];
    $scope.numOfNoises = $scope.options[2];
    if (mobileService.isMobile) {
      $scope.numOfHums = $scope.options[0];
      $scope.numOfNoises = $scope.options[1];
    }
    playHum = function() {
      var i, play, _results;
      play = function() {
        var hum, settings;
        settings = _.extend({}, settingsService.frequencies, settingsService.humSettings, settingsService.reverbSettings);
        hum = new Hum(settings);
        hum.onendCallback = play;
        return hum.output.connect(mainMix);
      };
      i = 0;
      _results = [];
      while (i < $scope.numOfHums.id) {
        play();
        _results.push(i++);
      }
      return _results;
    };
    playNoise = function() {
      var i, play, _results;
      play = function() {
        var noise, settings;
        settings = _.extend({}, settingsService.humSettings, settingsService.reverbSettings);
        noise = new Noise(settings);
        noise.onendCallback = play;
        return noise.output.connect(mainMix);
      };
      i = 0;
      _results = [];
      while (i < $scope.numOfNoises.id) {
        play();
        _results.push(i++);
      }
      return _results;
    };
    animationLoop = function() {
      spectrum.analyse();
      return requestAnimationFrame(animationLoop);
    };
    requestAnimationFrame(animationLoop);
    stopHum = function() {
      return _.each(hums, function(hum) {
        var e;
        try {
          hum.onendCallback = function() {};
          return hum.soundSource.stop(context.currentTime);
        } catch (_error) {
          e = _error;
          return window.location.reload();
        }
      });
    };
    stopNoise = function() {
      return _.each(noises, function(noise) {
        var e;
        try {
          noise.onendCallback = function() {};
          return noise.soundSource.stop(context.currentTime);
        } catch (_error) {
          e = _error;
          return window.location.reload();
        }
      });
    };
    $scope.humControl = function() {
      if ($scope.humOn) {
        return playHum();
      } else {
        return stopHum();
      }
    };
    return $scope.noiseControl = function() {
      if ($scope.noiseOn) {
        return playNoise();
      } else {
        return stopNoise();
      }
    };
  });

  controllers.controller('noise', function($scope, settingsService) {
    return $scope.noises = settingsService.noiseSettings;
  });

  controllers.controller('hum', function($scope, settingsService) {
    return $scope.hums = settingsService.humSettings;
  });

  controllers.controller('effects', function($scope, settingsService) {
    return $scope.reverb = settingsService.reverbSettings;
  });

  controllers.controller('about', function($scope) {});

  directives = angular.module('whitecaps.directives', []);

  directives.directive('dial', function($document) {
    return {
      restrict: "E",
      scope: {
        model: "=",
        active: "&",
        deactive: "&"
      },
      replace: true,
      template: "<div class=\"dial\" ng-class=\"{over: model > 50}\">\n  <div class=\"circle display\"></div>\n  <div class=\"circle fill\"></div>\n  <div class=\"mask\"></div>\n  <div class=\"center\">\n    <div class=\"display\"></div>\n  </div>\n</div>",
      link: function(scope, element, attrs) {
        var center, circleSize, display, lazyResize, titleBar;
        titleBar = angular.element('.title-bar');
        center = element.find('.center');
        display = element.find('.display');
        element.on('mousedown touchstart', function(e) {
          var downY, _ref;
          e.preventDefault();
          downY = (_ref = e.pageY) != null ? _ref : e.originalEvent.touches[0].pageY;
          scope.$apply(scope.active);
          return $document.on('mousemove touchmove', function(e) {
            var currentY, deg, distanceY, scaleFactor, _ref1;
            currentY = (_ref1 = e.pageY) != null ? _ref1 : e.originalEvent.touches[0].pageY;
            distanceY = currentY - downY;
            scaleFactor = Math.floor(Math.log(Math.abs(distanceY) + 1) / Math.LN10) + 1;
            if (currentY > downY) {
              scope.model = scope.model < 100 - scaleFactor ? scope.model + scaleFactor : 100;
            } else {
              scope.model = scope.model > 0 + scaleFactor ? scope.model - scaleFactor : 0;
            }
            scope.$apply(function() {
              return scope.model;
            });
            deg = Math.round(scope.model * 0.01 * 360);
            display.css('transform', "rotate(" + deg + "deg)");
            downY = currentY;
            return $document.bind('mouseup touchend', function(e) {
              $document.unbind('mousemove touchmove');
              $document.unbind('mouseup touchend');
              return scope.$apply(scope.deactive);
            });
          });
        });
        circleSize = function() {
          var docHeight, position, size, thickness;
          docHeight = $document.height();
          size = docHeight / 3;
          position = (docHeight / 4 - size / 2) - titleBar.height() / 4;
          thickness = size / 2;
          element.width(size);
          element.height(size);
          center.width(size - thickness);
          center.height(size - thickness);
          if (element.hasClass("top")) {
            return element.css('top', position);
          } else if (element.hasClass("bottom")) {
            return element.css('bottom', position);
          }
        };
        circleSize();
        lazyResize = _.debounce(circleSize, 100);
        return $(window).on('resize', function(e) {
          return lazyResize();
        });
      }
    };
  });

  directives.directive('slider', function($document) {
    return {
      restrict: "E",
      scope: {
        model: "=",
        active: "&",
        deactive: "&"
      },
      replace: true,
      template: "<div class=\"slider\">\n  <div class=\"slider__handle-min\"></div>\n  <div class=\"slider__handle-max\"></div>\n</div>",
      link: function(scope, element, attrs) {
        var allSliders, bindHandles, getY, handles, lazyResize, maxHeight, scale, scaledHeight, setInitialValues, sliderHover, titleBar, titleBarHeight, titleBarHover, unbindHandles, updateValues;
        maxHeight = 0;
        scaledHeight = 0;
        titleBarHeight = 0;
        handles = [element.find('.slider__handle-max'), element.find('.slider__handle-min')];
        titleBar = angular.element('.title-bar');
        scale = scope.model.scale[1] - scope.model.scale[0];
        allSliders = angular.element('.slider');
        titleBarHover = false;
        sliderHover = false;
        titleBar.on('mousedown touchstart', function() {
          return titleBarHover = true;
        });
        titleBar.on('mouseup touchend', function() {
          titleBarHover = false;
          if (sliderHover === false) {
            scope.$apply(scope.deactive);
            return allSliders.removeClass('active');
          }
        });
        element.on('mousedown touchstart', function(e) {
          var enter;
          sliderHover = true;
          enter = function() {
            scope.$apply(scope.active);
            allSliders.removeClass('active');
            return element.addClass('active');
          };
          return setTimeout(enter, 1);
        });
        element.on('mouseup touchend', function(e) {
          var leave;
          sliderHover = false;
          leave = function() {
            if (titleBarHover) {
              return;
            }
            scope.$apply(scope.deactive);
            return allSliders.removeClass('active');
          };
          return setTimeout(leave, 1);
        });
        setInitialValues = function() {
          var maxY, minY;
          maxHeight = $document.height() - 50;
          titleBarHeight = titleBar.height();
          scaledHeight = maxHeight - titleBarHeight - 48;
          element.css('height', maxHeight + "px");
          if (scope.model.minValue > scope.model.maxValue) {
            return;
          }
          minY = Math.abs(scaledHeight * scope.model.minValue / scope.model.scale[1]);
          maxY = scaledHeight - (scaledHeight * scope.model.maxValue / scope.model.scale[1]);
          if (scope.model.scale[0] < 0) {
            minY = (scaledHeight - minY) / 2;
            maxY = maxY / 2;
          }
          handles[0].css('top', maxY + 'px');
          return handles[1].css('bottom', minY + 'px');
        };
        getY = function(e) {
          var _ref;
          return ((_ref = e.pageY) != null ? _ref : e.originalEvent.touches[0].pageY) - 25;
        };
        updateValues = function(y, index) {
          var percent, position;
          position = 'top';
          if (index === 1) {
            y = maxHeight - y;
            position = 'bottom';
          }
          if (0 > y || y > scaledHeight / 2) {
            return;
          }
          handles[index].css(position, y + 'px');
          percent = y / scaledHeight;
          if (index === 0) {
            scope.model.maxValue = (1 - percent) * scale + scope.model.scale[0];
          }
          if (index === 1) {
            scope.model.minValue = percent * scale + scope.model.scale[0];
          }
          return scope.$apply(function() {
            return scope.model;
          });
        };
        unbindHandles = function() {
          return $document.bind('mouseup touchend', function(e) {
            $document.unbind('mousemove touchmove');
            return $document.unbind('mouseup touchend');
          });
        };
        bindHandles = function(index) {
          return handles[index].on('mousedown touchstart', function(e) {
            e.preventDefault();
            updateValues(getY(e), index);
            unbindHandles();
            return $document.on('mousemove touchmove', function(e) {
              updateValues(getY(e), index);
              return unbindHandles();
            });
          });
        };
        bindHandles(0);
        bindHandles(1);
        setInitialValues();
        lazyResize = _.debounce(setInitialValues, 100);
        return $(window).on('resize', function(e) {
          return lazyResize();
        });
      }
    };
  });

  services = angular.module('whitecaps.services', []);

  services.factory('settingsService', function() {
    return {
      'noiseSettings': {
        'attack': {
          minValue: 10,
          maxValue: 70,
          scale: [0, 100]
        },
        'length': {
          minValue: 5,
          maxValue: 30,
          scale: [3, 40]
        },
        'shape': {
          minValue: 500,
          maxValue: 3000,
          scale: [0, 5000]
        },
        'motion': {
          minValue: -60,
          maxValue: 75,
          scale: [-90, 90]
        }
      },
      'humSettings': {
        'attack': {
          minValue: 10,
          maxValue: 50,
          scale: [0, 100]
        },
        'length': {
          minValue: 10,
          maxValue: 20,
          scale: [3, 30]
        },
        'shape': {
          minValue: 500,
          maxValue: 3000,
          scale: [0, 5000]
        },
        'motion': {
          minValue: -45,
          maxValue: 87,
          scale: [-90, 90]
        }
      },
      'frequencies': {
        'low': [82.4, 110, 123.46, 130.81]
      },
      'reverbSettings': {
        'amount': 45,
        'roomSize': 80
      }
    };
  });

  services.factory('mobileService', function() {
    var isMobile, matchers, ua;
    isMobile = false;
    ua = navigator.userAgent;
    matchers = [/iPhone/i, /iPod/i, /iPad/i, /(?=.*\bAndroid\b)(?=.*\bMobile\b)/i, /Android/i];
    _.each(matchers, function(match) {
      if (match.test(ua)) {
        return isMobile = true;
      }
    });
    return {
      isMobile: isMobile
    };
  });

}).call(this);
