class Reverb
  constructor: () ->
    # Constants
    @mix = 0.33
    @fixedGain = 0.015
    @damping = 0.7
    @scaleDamping = 0.3
    @roomSize = 0.5
    @scaleRoom = 0.28
    @offsetRoom = 0.7
    @combTuning = [1116, 1188, 1277, 1356, 1422, 1491, 1557, 1617]
    @allPassTuning = [556, 441, 341, 225]

    # Damped comb filters
    @combBuffers = []
    @combIndices = []
    @filterStores = []

    i = 0
    while i < @combTuning.length
      @combBuffers.push new Float32Array(@combTuning[i])
      @combIndices.push 0
      @filterStores.push 0
      i++


    # All-pass filters
    @allPassBuffers = []
    @allPassIndices = []

    j = 0
    while j < @allPassTuning.length
      @allPassBuffers.push new Float32Array(@allPassTuning[j])
      @allPassIndices.push 0
      j++

  processSample: (sample) ->

    value = sample
    dryValue = value

    value *= @fixedGain
    gainedValue = value

    damping = @damping * @scaleDamping
    feedback = @roomSize * @scaleRoom + @offsetRoom

    i = 0

    while i < @combTuning.length
      combIndex = @combIndices[i]
      combBuffer = @combBuffers[i]
      filterStore = @filterStores[i]
      output = combBuffer[combIndex]

      filterStore = (output * (1 - damping)) + (filterStore * damping)
      value += output
      combBuffer[combIndex] = gainedValue + feedback * filterStore

      combIndex += 1
      if combIndex >= combBuffer.length
        combIndex = 0

      @combIndices[i] = combIndex
      @filterStores[i] = filterStore
      i++

    j = 0
    while j < @allPassTuning.length
      allPassBuffer = @allPassBuffers[j]
      allPassIndex = @allPassIndices[j]
      input = value
      bufferValue = allPassBuffer[allPassIndex]

      value = -value + bufferValue
      allPassBuffer[allPassIndex] = input + (bufferValue * 0.5)

      allPassIndex += 1
      if allPassIndex >= allPassBuffer.length
        allPassIndex = 0

      @allPassIndices[j] = allPassIndex
      j++
      
    return @mix * value + (1 - @mix) * dryValue
