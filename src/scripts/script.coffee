class Timeline
  constructor: ->

    @$years = $ '#timelineYears'
    @$events = $ '#timelineEvents'
    @$lightbox = $ '#timelineLightbox'

    @showLightboxId = ''

    @setEvents()
    @fetch()

  setEvents: ->
    $ '#controllerPlus'
      .click (e) =>
        @oneUnitYearWith += 10
        @renderYears()

    $ '#controllerMinus'
      .click (e) =>
        @oneUnitYearWith -= 10
        @renderYears()

    @$events.on 'click', '.event--lightbox', (e) =>
      $ 'body, html'
        .css
          overflow: 'hidden'
      @showLightboxId  = $(e.target).parents('.event--lightbox').data('id')
      $ '.lightbox [data-id=' + @showLightboxId + ']'
        .fadeIn()
      @$lightbox
        .css
          left: $(window).scrollLeft()
        .fadeIn()

    $ '#lightboxClose'
      .click (e) =>
        $ 'body, html'
          .css
            overflow: 'initial'
        $ '.lightbox [data-id=' + @showLightboxId + ']'
          .fadeOut()
        @$lightbox.fadeOut()

  fetch: ->
    $.ajax
      url: 'data/timeline.json'
      success: (data, status, xhr) =>
        @events = data.events
        @oneUnitYearWith = data.config.oneUnitYearWidth || 100
        @yearUnit = data.config.yearUnit || 10
        @startYear = data.config.start_year
        @endYear = data.config.end_year
        @renderYears()
        @renderLightbox()

  renderYears: ->
    @$years.empty()
    i = @startYear
    while i <= @endYear
      if i % @yearUnit is 0
        $ '<div></div>'
          .addClass 'timeline__year'
          .css
            width: @oneUnitYearWith + 'px'
          .append '<span></span>'
            .find 'span'
            .addClass 'timeline__yearNum'
            .addClass if i % 100 is 0 then 'timeline__yearNum--hundred'
            .text if i % 100 is 0 then i else i.toString().match(/\d{2}$/)
            .end()
          .appendTo @$years
      i++
    @adjustOverlapYears()

  adjustOverlapYears: ->
    scale = [2, 5, 10]
    i = 0
    while @isOverlapYears() or i is scale.length
      $ '.timeline__yearNum'
        .not '.timeline__yearNum--hundred'
        .hide()
        .each (index, el) ->
          $el = $ el
          if ($el.text() / 10) % scale[i] is 0
            $el.show()
      i++

    @renderEvents()

  isOverlapYears: ->
    isOverlap = false
    $prevElement = ''
    $ '.timeline__yearNum'
      .not '.timeline__yearNum--hundred'
      .filter ':visible'
      .each (index, el) ->
        return if isOverlap

        $el = $ el

        if index is 0
          $prevElement = $el
          return

        if $el.offset().left < $prevElement.offset().left + $prevElement.outerWidth()
          isOverlap = true

        $prevElement = $el

    return isOverlap

  renderEvents: ->
    @$events.empty()
    @events.forEach (event, index) =>
      lightboxClass = if event.lightbox then 'event--lightbox' else ''
      $ '<div></div>'
        .attr 'data-id', index
        .addClass 'timeline__event event ' + lightboxClass
        .css
          top: '0'
          left: (event.start_year * @oneUnitYearWith / @yearUnit) + 'px'
        .append '<span></span>'
          .find 'span'
          .addClass 'event__time'
          .css
            width: ((event.end_year - event.start_year) * @oneUnitYearWith / @yearUnit) + 'px'
          .end()
        .append '<span></span>'
          .find 'span:nth-child(2)'
          .addClass 'event__text'
          .text event.text
          .end()
        .appendTo @$events
    @adjustOverlapEvents()

  adjustOverlapEvents: ->
    leftEvents = []
    $ '.event'
      .each (index, el) ->
        $el = $ el
        loopEnd = ''

        if index is 0
          leftEvents.push {row: $el.offset().top, $el: $el}
          return

        leftEvents.forEach (leftEvent, index2, array) ->
          return if loopEnd

          if $el.offset().left > leftEvent.$el.offset().left + leftEvent.$el.outerWidth()
            loopEnd = true
            leftEvents.splice index2, 1, {row: $el.offset().top, $el: $el}
          else
            $el.css
              top: $el.outerHeight() * (index2 + 1)

          if leftEvents.length - 1 is index2
            leftEvents.push {row: $el.offset().top, $el: $el}

  renderLightbox: ->
    @events.forEach (event, index) =>
      if event.lightbox
        $ '<div></div>'
          .addClass 'lightbox__item'
          .attr 'data-id', index
          .append '<img/>'
            .find 'img'
            .attr 'src', event.lightbox.img
            .end()
          .append '<p></p>'
            .find 'p'
            .text event.lightbox.text
            .end()
          .appendTo @$lightbox

new Timeline()
