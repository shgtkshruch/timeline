class Timeline
  constructor: ->

    @$years = $ '#timelineYears'
    @$events = $ '#timelineEvents'
    @$lightbox = $ '#timelineLightbox'
    @$categories = $ '#timelineCategory'

    @showLightboxId = ''

    @setEvents()
    @fetch()

  setEvents: ->
    $ '#controllerPlus'
      .click (e) =>
        if @oneUnitYearWith < 10
          @oneUnitYearWith++
        else
          @oneUnitYearWith += 10
        @renderYears()

    $ '#controllerMinus'
      .click (e) =>
        if @oneUnitYearWith is 1
          return
        else if (@oneUnitYearWith - 10) <= 0
          @oneUnitYearWith--
        else
          @oneUnitYearWith -= 10
        @renderYears()

    @$events.on 'click', '.event--lightbox', (e) =>
      $ 'html'
        .css
          overflow: 'hidden'
      @showLightboxId  = $(e.target).closest('.event--lightbox').data('id')
      $ '.lightbox [data-id=' + @showLightboxId + ']'
        .fadeIn()
      @$lightbox
        .css
          left: $(window).scrollLeft()
        .fadeIn()

    $ '#lightboxClose'
      .click (e) =>
        $ 'html'
          .css
            overflow: 'initial'
        $ '.lightbox [data-id=' + @showLightboxId + ']'
          .fadeOut()
        @$lightbox.fadeOut()

    @$categories.on 'change', (e) =>
      @filteringByCategory()

  fetch: ->
    $.ajax
      url: 'data/timeline.json'
      success: (data, status, xhr) =>
        @events = data.events
        @oneUnitYearWith = parseInt data.config.oneUnitYearWidth, 10 || 100
        @yearUnit = parseInt data.config.yearUnit, 10 || 10
        @startYear = parseInt data.config.start_year, 10
        @endYear = parseInt data.config.end_year, 10

        @renderYears()
        @renderLightbox()

  renderYears: ->
    $fragment = $ document.createDocumentFragment()
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
            .text if i % 100 is 0 then i else i.toString().match(/\d{2}$/)
            .end()
          .appendTo $fragment
      i++
      $fragment.appendTo @$years
    @adjustOverlapYears()

  adjustOverlapYears: ->
    scale = [2, 5, 10, 100, 1000]
    i = 0
    while @isOverlapYears()
      $ '.timeline__yearNum'
          .parent()
          .css
            'border-left': 'none'
          .end()
        .hide()
        .each (index, el) ->
          $el = $ el
          if ($el.text() / 10) % scale[i] is 0
            $el
              .show()
              .parent()
              .css
                'border-left': '1px dashed rgba(255, 255, 255, .3)'
      i++
    @renderCategories()

  isOverlapYears: ->
    isOverlap = false
    $prevElement = ''
    $ '.timeline__yearNum'
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

  renderCategories: ->
    categories = []
    categoryTemplate = _.template $('#category-template').text()
    $fragment = $ document.createDocumentFragment()

    @events.forEach (event, index) ->
     if event.category
       categories.push event.category

    _.chain(categories).flattenDeep().uniq().value().forEach (category, index) ->
      $fragment.append categoryTemplate {value: category}

    $fragment.appendTo @$categories

    @filteringByCategory()

  filteringByCategory: ->
    removedCategories = []
    events = []

    @$categories.find('input:not(:checked)').each (index, el) ->
      removedCategories.push $(el).val()

    if removedCategories.length is 0
      @renderEvents @events
      return

    @events.forEach (event) ->
      if !event.category
        events.push event
        return

      mergeCategory = event.category.concat removedCategories
      if _.uniq(mergeCategory).length < event.category.length + removedCategories.length
        return

      events.push event

    @renderEvents events

  renderEvents: (events) ->
    $fragment = $ document.createDocumentFragment()
    eventTemplate = _.template $('#event-template').text()

    @$events.empty()

    _.chain(events)
      .sortBy((n) -> parseInt n.start_year, 10)
      .value()
      .forEach (event, index) =>
        event.start_year = parseInt event.start_year, 10
        event.end_year = parseInt event.end_year, 10

        ev = {}
        ev.id = index
        ev.klass = if event.lightbox then 'event--lightbox' else ''
        ev.left = ((Math.abs(@startYear) + event.start_year) * @oneUnitYearWith / @yearUnit) + 'px'
        ev.timeWidth = ((event.end_year - event.start_year) * @oneUnitYearWith / @yearUnit) + 'px'
        ev.period = event.start_year + if event.end_year then ' ~ ' + event.end_year else ''
        ev.text = event.text
        $fragment.append eventTemplate ev

    $fragment.appendTo @$events

    @adjustOverlapEvents()

  adjustOverlapEvents: ->
    leftEvents = []
    $ '.event'
      .each (index, el) ->
        $el = $ el
        loopEnd = false

        if index is 0
          leftEvents.push {row: $el.offset().top, $el: $el}
        else
          leftEvents.forEach (leftEvent, index2) ->
            return if loopEnd
            if $el.offset().left > leftEvent.$el.offset().left + leftEvent.$el.outerWidth()
              loopEnd = true
              leftEvents.splice index2, 1, {row: $el.offset().top, $el: $el}
            else
              $el.css
                top: leftEvent.row + $el.outerHeight()
              if index2 is leftEvents.length - 1
                leftEvents.push {row: $el.offset().top, $el: $el}

  renderLightbox: ->
    $fragment = $ document.createDocumentFragment()
    lightboxTemplate = _.template $('#lightbox-template').text()

    _.chain(@events)
      .sortBy((n) -> parseInt n.start_year, 10)
      .value()
      .forEach (event, index) =>
        if event.lightbox
          lightbox = {}
          lightbox.id = index
          lightbox.src = event.lightbox.img
          lightbox.text = event.lightbox.text
          $fragment.append lightboxTemplate lightbox

    $fragment.appendTo @$lightbox

new Timeline()
