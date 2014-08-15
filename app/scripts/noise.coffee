window.AudioContext = window.AudioContext || window.webkitAudioContext
context = new AudioContext()
context.listener.setPosition(0, 0, 0)

# mainMix = context.createGainNode()
# meter = context.createScriptProcessor(2048, 1, 1)
compressor = context.createDynamicsCompressor();

# meter.onaudioprocess = processAudio
# mainMix.connect(meter)
# meter.connect(context.destination)
# mainMix.gain.value = 0.8
# mainMix.connect(compressor)
compressor.connect(context.destination)

notes = []
noises = []

# processAudio = (e) ->
#   buffer = e.inputBuffer.getChannelData(0)
#   isClipping = false
#
#   # Iterate through buffer to check if any of the |values| exceeds 1.
#   i = 0
#
#   while i < buffer.length
#     absValue = Math.abs(buffer[i])
#     if absValue >= 1
#       # break
#     i++


class Whitecap
  constructor: (@length = 10, @delay = 0) ->
    @filter = context.createBiquadFilter()
    @adsr = context.createGainNode()
    @panner = context.createPanner()
    noteGain = context.createGainNode()
    noteGain.gain.value = 0.3 / notes.length + 1
    noiseGain = context.createGainNode()
    noiseGain.gain.value = 0.6 / noises.length + 1
    masterGain = context.createGainNode()
    masterGain.gain.value = 0.5
    @panner.setPosition(0, 0, 1)
    @panner.panningModel = 'equalpower'
    reverb = context.createConvolver()
    reverb.buffer = createImpulse(@length/2)
    reverb.buffer.gain = 0.5

    @soundSource.connect(noteGain) if @soundSource.constructor.name == 'OscillatorNode'
    @soundSource.connect(noiseGain) if @soundSource.constructor.name == 'AudioBufferSourceNode'
    noteGain.connect(masterGain)
    noiseGain.connect(masterGain)
    masterGain.connect(reverb)
    reverb.connect(@filter)
    @filter.connect(@adsr)
    @adsr.connect(@panner)
    @panner.connect(mainMix)

    @begin = context.currentTime + @delay
    @end = @begin + @length

    @soundSource.start(@begin)
    @soundSource.stop(@end)

    @automateFilter()
    @automateVolume()
    @automatePanning()

    @soundSource.onended = noteEnded

  automateFilter: () ->
    attack =
      cutoffTime: (@end - @begin) * randomRange(10, 50)/100 + @begin
      cutoff: randomRange(500, 3000)
      Q: randomRange(1, 6)
      QTime:(@end - @begin) * randomRange(10, 50)/100 + @begin

    decay =
      cutoffTime: attack.QTime + 3
      cutoff: randomRange(500, 3000)
      Q: randomRange(1, 6)
      QTime: attack.QTime + 2


    @filter.frequency.setValueAtTime(400, @begin)
    @filter.frequency.linearRampToValueAtTime(attack.cutoffTime, attack.cutoff)
    @filter.frequency.linearRampToValueAtTime(decay.cutoffTime, decay.cutoff)
    @filter.frequency.linearRampToValueAtTime(200, @end)

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
    changePan = (val) =>
      xDeg = parseInt val
      zDeg = xDeg + 90
      zDeg = 180 - zDeg  if zDeg > 90

      x = Math.sin(xDeg * (Math.PI / 180))
      y = 0
      z = Math.sin(zDeg * (Math.PI / 180))
      @panner.setPosition x, y, z

    startPan = randomRange(-90, 90)
    endPan = randomRange(-90, 90)

    distance = Math.abs(startPan - endPan)

    incrementPan = () =>
      if startPan < endPan
        num = startPan+= 0.1
        clearInterval(interval) if num > endPan - 0.1
      else
        num = startPan-=0.1
        clearInterval(interval) if num < endPan + 0.1

      changePan(num)

    interval = setInterval incrementPan, @length * 100 / distance

class Noise extends Whitecap
  constructor: (@length, @delay, color = 'pink')->
    @soundSource = context.createBufferSource()
    colors = ['white', 'brown', 'pink']
    @soundSource.buffer = generateNoiseBuffer @length, colors[randomRange(0, 2)]

    super @length, @delay
    noises.push @soundSource

class Note extends Whitecap
  constructor: (@length, @delay)->
    @soundSource = context.createOscillator()
    @soundSource.type = 'triangle'
    super
    @automateFrequeny()
    notes.push @soundSource

  automateFrequeny: () ->
    freqs = [110, 261.6, 220]
    freq = freqs[[randomRange(0, 2)]]
    @soundSource.frequency.setValueAtTime freq, @begin
    @soundSource.frequency.linearRampToValueAtTime freq + randomRange(-15, 15), @begin + 2
    @soundSource.frequency.linearRampToValueAtTime freq, @end

randomRange = (min, max) ->
  ~~(Math.random() * (max - min + 1)) + min

createImpulse = (len) ->
  rate = context.sampleRate
  length = rate * len
  decay = 20
  impulse = context.createBuffer(1, length, rate)
  impulseL = impulse.getChannelData(0)
  i = 0
  while i < length
    impulseL[i] = (Math.random() * 2 - 1) * Math.pow(1 - i / length, decay)
    i++
  impulse

generateNoiseBuffer = (length, color) ->
  console.log "color: #{color}"
  _length = context.sampleRate * length
  arrayBuffer = new Float32Array _length
  white = () -> 2 * Math.random() - 1
  i = 0
  if color == 'white'
    while(i < _length)
      arrayBuffer[i] = white()
      i++

  if color == 'pink'
    b0 = b1 = b2 = b3 = b4 = b5 = b6 = 0.0
    while(i < _length)
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

  if color == 'brown'
    lastOut = 0.0
    while(i < _length)
      arrayBuffer[i] = (lastOut + (0.02 * white())) / 1.02
      lastOut = arrayBuffer[i]
      arrayBuffer[i] *= 3.5
      i++

  audioBuffer = context.createBuffer(1, _length, context.sampleRate)
  audioBuffer.getChannelData(0).set(arrayBuffer)
  return audioBuffer

makeNoise = () ->
  noise = new Noise randomRange(5, 20), randomRange(0, 2)
  note = new Note randomRange(2, 10), randomRange(0, 3)

play = () ->
  makeNoise()
  interval = setInterval makeNoise, randomRange(5000, 10000)

noteEnded = (e) ->
  type = e.target.constructor.name
  notes.shift() if type == "OscillatorNode"
  noises.shift() if type == "AudioBufferSourceNode"
  console.log "notes: #{notes.length}, noises: #{noises.length}"

#document.querySelector('#play').addEventListener 'mouseup', play
