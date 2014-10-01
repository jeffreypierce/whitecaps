canvas = document.querySelector("canvas")
canvasContext = canvas.getContext("2d")

class Spectrum
  constructor: (context) ->
    @analyser = context.createAnalyser()
    @barWidth = 24
    @barSpacing = -12

  analyse: () ->
    width = canvas.width
    height = canvas.height
    frequencyData = new Uint8Array(@analyser.frequencyBinCount)
    frequencyData = frequencyData.subarray(100, 400)
    @analyser.getByteFrequencyData(frequencyData)
    canvasContext.clearRect 0, 0, width, height
    barCount = Math.round(width / (@barWidth + @barSpacing))
    loopStep = Math.floor(frequencyData.length / barCount)
    i = 0
    while i < barCount
      barHeight = frequencyData[i * loopStep] * (height / 255)
      alpha = (barHeight / width)
      canvasContext.fillStyle = "rgba(235,239,240,#{alpha})"
      canvasContext.fillRect ((@barWidth + @barSpacing) * i) +
        (@barSpacing / 2), height, @barWidth - @barSpacing, -barHeight
      i++
