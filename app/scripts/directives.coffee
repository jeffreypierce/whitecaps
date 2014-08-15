directives = angular.module 'whitecaps.directives', []

directives.directive 'dial', ($document) ->
  restrict: "E"
  scope:
    model: "="
  replace: true
  template: """
    <div class="dial" ng-class="{over: model > 50}">
      <div class="circle display"></div>
      <div class="circle fill"></div>
      <div class="mask"></div>
      <div class="center">
        <div class="value">{{model}}<div>
      </div>
    </div>
    """
  link: (scope, element, attrs) ->
    display = angular.element('.display')
    element.on 'mousedown touchstart', (e) ->
      e.preventDefault()
      downY = e.pageY ? e.originalEvent.touches[0].pageY

      $document.on 'mousemove touchmove', (e) ->
        currentY = e.pageY ? e.originalEvent.touches[0].pageY
        distanceY = currentY - downY
        scaleFactor = Math.floor(Math.log(Math.abs(distanceY) + 1) /
          Math.LN10) + 1

        if currentY > downY
          scope.model = if scope.model < 100 -
            scaleFactor then scope.model + scaleFactor else 100
        else
          scope.model = if scope.model > 0 +
            scaleFactor then scope.model - scaleFactor else 0
        scope.$apply ()-> scope.model
        deg = Math.round(scope.model * 0.01 * 360)
        display.css 'webkitTransform', "rotate(#{deg}deg)"

        downY = currentY

        $document.bind 'mouseup touchend', (e) ->
          $document.unbind 'mousemove touchmove'
          $document.unbind 'mouseup touchend'

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
      element.find('.slider__handle-max')
      element.find('.slider__handle-min')
    ]
    titleBar = angular.element('.title-bar')
    scale = scope.model.scale[1] - scope.model.scale[0]
    allSliders = angular.element('.slider')
    titleBarHover = false
    sliderHover = false

    titleBar.on 'mouseenter', () ->
      titleBarHover = true

    titleBar.on 'mouseleave', () ->
      titleBarHover = false
      if sliderHover == false
        scope.$apply(scope.deactive)
        allSliders.removeClass('active')

    element.on 'mouseenter', (e) ->
      sliderHover = true
      enter = ->
        scope.$apply(scope.active)
        allSliders.removeClass('active')
        element.addClass('active')
      setTimeout(enter, 1)

    element.on 'mouseleave', (e) ->
      sliderHover = false
      leave = ->
        return if titleBarHover
        scope.$apply(scope.deactive)
        allSliders.removeClass('active')

      setTimeout(leave, 1)


    setInitialValues = () ->
      maxHeight = $document.height() - 100
      titleBarHeight = titleBar.height()
      scaledHeight = (maxHeight - titleBarHeight - 48)
      element.css 'height', maxHeight + "px"

      return if scope.model.minValue > scope.model.maxValue
      minY = scaledHeight * scope.model.minValue/scope.model.scale[1]
      maxY = scaledHeight - (scaledHeight * scope.model.maxValue/scope.model.scale[1])
      handles[0].css('top', maxY + 'px')
      handles[1].css('bottom', minY + 'px')


    getY = (e) ->
      (e.pageY ? e.originalEvent.touches[0].pageY) - 50

    updateValues = (y, index) ->
      position = 'top'
      if index == 1
        y = maxHeight - y
        position = 'bottom'
      return if 0 > y || y > scaledHeight/2

      handles[index].css(position, y + 'px')

      percent = y/scaledHeight

      if index == 0
        scope.model.maxValue = (1 - percent) * scale + scope.model.scale[0]
      if index == 1
        scope.model.minValue = percent * scale + scope.model.scale[0]

      scope.$apply ()-> scope.model
      console.log scope.model.minValue, scope.model.maxValue

    unbindHandles = ->
      $document.bind 'mouseup touchend', (e) ->
        $document.unbind 'mousemove touchmove'
        $document.unbind 'mouseup touchend'


    bindHandles = (index) ->
      handles[index].on 'mousedown touchstart', (e) ->
        e.preventDefault()
        updateValues(getY(e), index)
        unbindHandles()
        $document.on 'mousemove touchmove', (e) ->

          updateValues(getY(e), index)
          unbindHandles()

    bindHandles(0)
    bindHandles(1)
    setInitialValues()

    lazyResize = _.debounce(setInitialValues, 100)

    $(window).on 'resize', (e) ->
      lazyResize()
