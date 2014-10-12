class Whitecap
  constructor: (settings) ->
    @settings = settings
    @length = randomRange settings.length.minValue, settings.length.maxValue
    @delay = randomRange settings.length.minValue, settings.length.maxValue / 3
    @vol = 0.8
    @filter = context.createBiquadFilter()
    @adsr = context.createGain()
    @panner = context.createPanner()
    @output = context.createGain()
    wet = context.createGain()
    dry = context.createGain()
    reverb = context.createConvolver()
    reverbBuffer = generateImpulse()
    @type = @soundSource.constructor.name

    reverb.buffer = reverbBuffer

    if @type  == 'OscillatorNode'
      @output.gain.value = 0.3
      notes.push @

    if @type == 'AudioBufferSourceNode'
      @output.gain.value = @vol
      noises.push @

    @panner.setPosition 0, 0, 1
    @panner.panningModel = 'equalpower'

    @soundSource.connect reverb
    @soundSource.connect dry

    reverb.connect wet

    wet.gain.value = 0.8
    dry.gain.value = 0.5

    dry.connect @filter
    wet.connect @filter

    @filter.connect @adsr
    @adsr.connect @panner
    @panner.connect @output

    @begin = context.currentTime + @delay
    @end = @begin + @length

    @soundSource.start @begin
    @soundSource.stop @end

    @automateFilter()
    @automateVolume()
    @automatePanning()

    @soundSource.onended = @noteEnded

    @onendCallback = ->

    console.log @
  automateFilter: () ->
    attackTime = (@end - @begin) * randomRange(10, 50) / 100 + @begin
    decayTime = (@end - @begin) * randomRange(50, 80) / 100 + @begin

    attack =
      cutoff: randomRange(@settings.shape.minValue, @settings.shape.maxValue)
      Q: randomRange(1, 6)
    decay =
      cutoff: randomRange(@settings.shape.minValue, @settings.shape.maxValue)
      Q: randomRange(1, 6)

    @filter.frequency.setValueAtTime(randomRange(0, @settings.shape.minValue), @begin)
    @filter.frequency.linearRampToValueAtTime(attack.cutoff, attackTime)
    @filter.frequency.linearRampToValueAtTime(decay.cutoff, decayTime)
    @filter.frequency.linearRampToValueAtTime(randomRange(0, @settings.shape.minValue), @end)

    @filter.Q.setValueAtTime(5, @begin)
    @filter.Q.linearRampToValueAtTime(attack.Q, attackTime)
    @filter.Q.linearRampToValueAtTime(decay.Q, decayTime)
    @filter.Q.linearRampToValueAtTime(1, @end)

  automateVolume: () ->
    attackTime = (@end - @begin) * randomRange(10, 50) / 100 + @begin
    decayTime = (@end - @begin) * randomRange(50, 80) / 100 + @begin

    attackGain = randomRange(@settings.amount.minValue, @settings.amount.minValue) / 100
    decayGain = randomRange(@settings.amount.minValue, @settings.amount.minValue) / 100

    @adsr.gain.setValueAtTime(0, @begin)
    @adsr.gain.linearRampToValueAtTime(attackGain, attackTime)
    @adsr.gain.linearRampToValueAtTime(decayGain, decayTime)
    @adsr.gain.linearRampToValueAtTime(0, @end)

  automatePanning: () ->
    startPan = randomRange @settings.motion.minValue, @settings.motion.maxValue
    endPan = randomRange @settings.motion.minValue, @settings.motion.maxValue
    distance = Math.abs startPan - endPan

    incrementPan = () =>
      if startPan < endPan
        num = startPan+= 1
        clearInterval(interval) if num > endPan - 1
      else
        num = startPan-=1
        clearInterval(interval) if num < endPan + 1

      xDeg = parseInt num
      zDeg = xDeg + 90
      zDeg = 180 - zDeg if zDeg > 90
      x = Math.sin xDeg * (Math.PI / 180)
      z = Math.sin zDeg * (Math.PI / 180)

      @panner.setPosition x, 0, z

    interval = setInterval incrementPan, @length * 1000 / distance

  noteEnded: (e) =>
    notes.shift() if @type == "OscillatorNode"
    noises.shift() if @type == "AudioBufferSourceNode"

    @onendCallback()

class Noise extends Whitecap
  constructor: (settings)->
    @soundSource = context.createBufferSource()
    colors = ['white', 'brown', 'pink']
    @soundSource.buffer = generateNoiseBuffer randomRange(settings.length.minValue, settings.length.maxValue), colors[randomRange(0, 2)]
    super

class Hum extends Whitecap
  constructor: (settings)->
    @soundSource = context.createOscillator()
    @soundSource.type = 'triangle'

    super
    @automateFrequeny()

  automateFrequeny: () ->
    freqs = @settings.frequencies
    freq = freqs[randomRange 0, freqs.length]
    @soundSource.frequency.setValueAtTime freq, @begin
    @soundSource.frequency.linearRampToValueAtTime freq + randomRange(-5, 5), @begin + randomRange(1, @length - 1)
    @soundSource.frequency.linearRampToValueAtTime freq, @end

#utility functions
randomRange = (min, max) ->
  ~~(Math.random() * (max - min + 1)) + min

generateImpulse = (length = 2, decay = 50) ->
  rate = context.sampleRate
  _length = rate * length
  impulse = context.createBuffer 1, _length, rate
  impulseChannel = impulse.getChannelData 0
  # impulseR = impulse.getChannelData 1
  i = 0
  while i < length
    impulseChannel[i] = (2 * Math.random() - 1) * Math.pow(1 - i / length, decay)
    i++
  impulse

generateNoiseBuffer = (length, color) ->
  _length = context.sampleRate * length
  arrayBuffer = new Float32Array _length
  white = () -> 2 * Math.random() - 1
  i = 0
  switch color
    when "white"
      while i < _length
        arrayBuffer[i] = white()
        i++

    when 'pink'
      b0 = b1 = b2 = b3 = b4 = b5 = b6 = 0.0
      while i < _length
        _white = white()
        b0 = 0.99886 * b0 + _white * 0.0555179
        b1 = 0.99332 * b1 + _white * 0.0750759
        b2 = 0.96900 * b2 + _white * 0.1538520
        b3 = 0.86650 * b3 + _white * 0.3104856
        b4 = 0.55000 * b4 + _white * 0.5329522
        b5 = -0.7616 * b5 - _white * 0.0168980
        arrayBuffer[i] = b0 + b1 + b2 + b3 + b4 + b5 + b6 + _white * 0.5362
        arrayBuffer[i] *= 0.11
        b6 = _white * 0.115926
        i++

    when 'brown'
      lastOut = 0.0
      while i < _length
        arrayBuffer[i] = (lastOut + (0.02 * white())) / 1.02
        lastOut = arrayBuffer[i]
        arrayBuffer[i] *= 3.5
        i++

  audioBuffer = context.createBuffer 1, _length, context.sampleRate
  audioBuffer.getChannelData(0).set arrayBuffer

  return audioBuffer

notes = []
noises = []
