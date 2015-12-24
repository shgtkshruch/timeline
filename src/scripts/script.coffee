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
      @showLightboxId  = $(e.target).parents('.event--lightbox').data('id')
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
        @oneUnitYearWith = data.config.oneUnitYearWidth || 100
        @yearUnit = data.config.yearUnit || 10
        @startYear = data.config.start_year
        @endYear = data.config.end_year

        @renderYears()
        @renderLightbox()
        @renderCategories()

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
                'border-left': '1px dashed #000'
      i++

    @filteringByCategory()

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
    @$events.empty()
    events.forEach (event, index) =>
      lightboxClass = if event.lightbox then 'event--lightbox' else ''
      $ '<div></div>'
        .attr 'data-id', index
        .addClass 'timeline__event event ' + lightboxClass
        .css
          top: '0'
          left: (Math.abs(@startYear) * @oneUnitYearWith / @yearUnit + event.start_year * @oneUnitYearWith / @yearUnit) + 'px'
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
        .appendTo $fragment

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
          .appendTo $fragment

    $fragment.appendTo @$lightbox

  renderCategories: ->
    categories = []
    categoryTemplate = _.template $('#category-template').text()
    $fragment = $ document.createDocumentFragment()

    @events.forEach (event, index) ->
     if event.category
       categories.push event.category

    _.chain(categories).flattenDeep().uniq().value().forEach (category, index) =>
      $fragment.append categoryTemplate {value: category}

    $fragment.appendTo @$categories

new Timeline()
