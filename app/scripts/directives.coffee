directives = angular.module 'whitecaps.directives', []

directives.directive 'dial', ($document) ->
  restrict: "E"
  scope:
    model: "="
    active: "&"
    deactive: "&"
  replace: true
  template: """
    <div class="dial" ng-class="{over: model > 50}">
      <div class="circle display"></div>
      <div class="circle fill"></div>
      <div class="mask"></div>
      <div class="center">
        <div class="display"></div>
      </div>
    </div>
    """
  link: (scope, element, attrs) ->
    titleBar = angular.element '.title-bar'
    center = element.find '.center'
    display = element.find '.display'
    element.on 'mousedown touchstart', (e) ->
      e.preventDefault()
      downY = e.pageY ? e.originalEvent.touches[0].pageY
      scope.$apply scope.active

      $document.on 'mousemove touchmove', (e) ->
        currentY = e.pageY ? e.originalEvent.touches[0].pageY
        distanceY = currentY - downY
        scaleFactor = Math.floor(Math.log(Math.abs(distanceY) + 1) / Math.LN10) + 1

        if currentY > downY
          scope.model = if scope.model < 100 -
            scaleFactor then scope.model + scaleFactor else 100
        else
          scope.model = if scope.model > 0 +
            scaleFactor then scope.model - scaleFactor else 0
        scope.$apply ()-> scope.model
        deg = Math.round(scope.model * 0.01 * 360)
        display.css 'transform', "rotate(#{deg}deg)"

        downY = currentY

        $document.bind 'mouseup touchend', (e) ->
          $document.unbind 'mousemove touchmove'
          $document.unbind 'mouseup touchend'
          scope.$apply scope.deactive

    circleSize = () ->
      docHeight = $document.height()
      size =  docHeight / 3
      position = (docHeight / 4 - size / 2 ) - titleBar.height() / 4
      thickness = size / 2

      element.width size
      element.height size

      center.width size - thickness
      center.height size - thickness

      if element.hasClass "top"
        element.css 'top', position
      else if element.hasClass "bottom"
        element.css 'bottom', position

    circleSize()
    lazyResize = _.debounce circleSize, 100

    $(window).on 'resize', (e) ->
      lazyResize()

directives.directive 'slider', ($document) ->
  restrict: "E"
  scope:
    model: "="
    active: "&"
    deactive: "&"
  replace: true
  template: """
    <div class="slider">
      <div class="slider__handle-min"></div>
      <div class="slider__handle-max"></div>
    </div>
    """
  link: (scope, element, attrs) ->
    maxHeight = 0
    scaledHeight = 0
    titleBarHeight = 0
    handles = [
      element.find '.slider__handle-max'
      element.find '.slider__handle-min'
    ]
    titleBar = angular.element '.title-bar'
    scale = scope.model.scale[1] - scope.model.scale[0]

    allSliders = angular.element '.slider'
    titleBarHover = false
    sliderHover = false

    titleBar.on 'mousedown touchstart', () ->
      titleBarHover = true

    titleBar.on 'mouseup touchend', () ->
      titleBarHover = false
      if sliderHover == false
        scope.$apply scope.deactive
        allSliders.removeClass 'active'

    element.on 'mousedown touchstart', (e) ->
      sliderHover = true
      enter = ->
        scope.$apply scope.active
        allSliders.removeClass 'active'
        element.addClass 'active'

      setTimeout enter, 1 # dirty hack to force function call order

    element.on 'mouseup touchend', (e) ->
      sliderHover = false
      leave = ->
        return if titleBarHover
        scope.$apply scope.deactive
        allSliders.removeClass 'active'

      setTimeout leave, 1 # dirty hack to force function call order


    setInitialValues = () ->
      maxHeight = $document.height() - 50
      titleBarHeight = titleBar.height()
      scaledHeight = maxHeight - titleBarHeight - 48
      element.css 'height', maxHeight + "px"

      return if scope.model.minValue > scope.model.maxValue
      minY = Math.abs(scaledHeight * scope.model.minValue / scope.model.scale[1])
      maxY = scaledHeight - (scaledHeight * scope.model.maxValue / scope.model.scale[1])

      # hack for scales that cross the zero boundry
      # TODO - find less coupled solution
      if scope.model.scale[0] < 0
        minY = (scaledHeight - minY) / 2
        maxY = maxY / 2

      handles[0].css 'top', maxY + 'px'
      handles[1].css 'bottom', minY + 'px'

    getY = (e) ->
      (e.pageY ? e.originalEvent.touches[0].pageY) - 25

    updateValues = (y, index) ->
      position = 'top'
      if index == 1
        y = maxHeight - y
        position = 'bottom'
      return if 0 > y || y > scaledHeight/2

      handles[index].css position, y + 'px'

      percent = y / scaledHeight

      if index == 0
        scope.model.maxValue = (1 - percent) * scale + scope.model.scale[0]
      if index == 1
        scope.model.minValue = percent * scale + scope.model.scale[0]

      scope.$apply ()-> scope.model

    unbindHandles = ->
      $document.bind 'mouseup touchend', (e) ->
        $document.unbind 'mousemove touchmove'
        $document.unbind 'mouseup touchend'

    bindHandles = (index) ->
      handles[index].on 'mousedown touchstart', (e) ->
        e.preventDefault()
        updateValues getY(e), index
        unbindHandles()
        $document.on 'mousemove touchmove', (e) ->
          updateValues getY(e), index

          unbindHandles()

    bindHandles 0
    bindHandles 1
    setInitialValues()

    lazyResize = _.debounce setInitialValues, 100

    $(window).on 'resize', (e) ->
      lazyResize()
