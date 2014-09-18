reverbBuffer = null
class Whitecap
  constructor: (context, settings) ->

    @length = settings.length || 10
    @delay = settings.delay || 0
    @vol = settings.vol || randomRange(5, 8) / 10
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
      @output.gain.value = (@vol * 0.3)
      notes.push @soundSource

    if @type == 'AudioBufferSourceNode'
      @output.gain.value = @vol
      noises.push @soundSource

    console.log "new #{@type}, #{@delay}, #{@length}"

    @panner.setPosition(0, 0, 1)
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

    @soundSource.start(@begin)
    @soundSource.stop(@end)

    @automateFilter()
    @automateVolume()
    @automatePanning()

    @soundSource.onended = _.debounce(@noteEnded, 1000)

    @onendCallback = ->

  automateFilter: () ->
    attack =
      cutoffTime: (@end - @begin) * randomRange(10, 50)/100 + @begin
      cutoff: randomRange(500, 5000)
      Q: randomRange(1, 6)
      QTime:(@end - @begin) * randomRange(10, 50)/100 + @begin
    decay =
      cutoffTime: attack.QTime + 3
      cutoff: randomRange(0, 4000)
      Q: randomRange(1, 6)
      QTime: attack.QTime + 2

    @filter.frequency.setValueAtTime(randomRange(0, 2000), @begin)
    @filter.frequency.linearRampToValueAtTime(attack.cutoffTime, attack.cutoff)
    @filter.frequency.linearRampToValueAtTime(decay.cutoffTime, decay.cutoff)
    @filter.frequency.linearRampToValueAtTime(randomRange(0, 1000), @end)

    @filter.Q.setValueAtTime(5, @begin)
    @filter.Q.linearRampToValueAtTime(attack.Q, attack.Qtime)
    @filter.Q.linearRampToValueAtTime(decay.Q, decay.Qtime)
    @filter.Q.linearRampToValueAtTime(1, @end)

  automateVolume: () ->
    attack =
      time: (@end - @begin) * randomRange(10, 50)/100 + @begin
      gain: randomRange(50, 90)/100
    decay =
      time: attack.time + 2
      gain: randomRange(30, 90)/100

    @adsr.gain.setValueAtTime(0, @begin)
    @adsr.gain.linearRampToValueAtTime(attack.gain, attack.time)
    @adsr.gain.linearRampToValueAtTime(decay.gain, decay.time)
    @adsr.gain.linearRampToValueAtTime(0, @end)

  automatePanning: () ->
    startPan = randomRange(-90, 90)
    endPan = randomRange(-90, 90)
    distance = Math.abs(startPan - endPan)

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
      x = Math.sin(xDeg * (Math.PI / 180))
      z = Math.sin(zDeg * (Math.PI / 180))

      @panner.setPosition x, 0, z

    interval = setInterval incrementPan, @length * 1000 / distance

  noteEnded: (e) =>
    notes.shift() if @type == "OscillatorNode"
    noises.shift() if @type == "AudioBufferSourceNode"

    @onendCallback()

class Noise extends Whitecap
  constructor: (context, settings)->
    @soundSource = context.createBufferSource()
    colors = ['white', 'brown', 'pink']
    @soundSource.buffer = generateNoiseBuffer settings.length, colors[randomRange(0, 2)]
    super

class Hum extends Whitecap
  constructor: (context, settings)->
    @soundSource = context.createOscillator()
    @soundSource.type = 'triangle'

    super
    @automateFrequeny()

  automateFrequeny: () ->
    freqs = [82.4, 110, 123.46, 130.81]
    freq = freqs[randomRange(0, 3)]
    @soundSource.frequency.setValueAtTime freq, @begin
    @soundSource.frequency.linearRampToValueAtTime freq + randomRange(-5, 5), @begin + randomRange(1, @length - 1)
    @soundSource.frequency.linearRampToValueAtTime freq, @end

#utility functions
randomRange = (min, max) ->
  ~~(Math.random() * (max - min + 1)) + min

generateImpulse = (length = 2, decay = 100) ->
  rate = context.sampleRate
  length = rate * length
  impulse = context.createBuffer 1, length, rate
  impulseChannel = impulse.getChannelData 0
  i = 0
  while i < length
    impulseChannel[i] = (2 * Math.random() - 1) * Math.pow(1 - i / length, decay)
    i++
  impulse

generateNoiseBuffer = (length, color) ->
  console.log color
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
