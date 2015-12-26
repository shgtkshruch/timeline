class Timeline
  constructor: ->

    @$years = $ '#timelineYears'
    @$events = $ '#timelineEvents'
    @$lightbox = $ '#timelineLightbox'
    @$categories = $ '#timelineCategory'
    @$categoryOrder = $ '#categoryOrder'

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

    @$events.on 'click', '.event', (e) =>
      $el = $(e.target).closest('.event')
      dataWikipedia = $el.data('wikipedia')
      text = dataWikipedia || $el.find('.event__text').text()
      url = ['https://jp.wikipedia.org/w/api.php?'
            'action=query',
            '&format=json',
            '&prop=extracts',
            '&exintro=',
            '&explaintext=',
            '&redirects=',
            '&titles=',
            text
            ].join('')

      $.ajax
        url: url
        dataType: 'jsonp'
        success: (data, status, xhr) =>
          pageId = Object.keys(data.query.pages)[0]
          content = if pageId isnt '-1'
            data.query.pages[pageId].extract
          else
            'Wikipediaに記事がありませんでした。'

          $lightboxInner = $ '#lightboxInner'
          padding = 20

          p = $ '<p></p>'
            .addClass 'lightbox__item'
            .text content

          @$lightbox
            .css
              left: $(window).scrollLeft()
            .find $lightboxInner
              .append p
              .end()
            .fadeIn()

          $ 'html'
            .css
              overflow: 'hidden'

          $ '#lightboxClose'
            .css
              top: $lightboxInner.offset().top + padding + 'px'
              left: $lightboxInner.position().left + $lightboxInner.outerWidth() - padding + 'px'

    $ '#lightboxClose'
      .click (e) =>
        $ 'html'
          .css
            overflow: 'initial'
        @$lightbox
          .fadeOut 400, ->
            $(@)
              .find '.lightbox__item'
              .remove()

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
        @renderCategories()
        @filteringByCategory()

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

  renderCategories: ->
    categories = []
    selectedCategory =
      kind: ['human', 'event']
      region: ['egypt', 'europe', 'china', 'japan', 'india']
      occupation: ['art', 'scholar', 'religion']
      others: []
    selectedCategoryArray = _.chain(selectedCategory).values().flatten().value()

    categoryTemplate = _.template $('#category-template').text()
    $fragment = $ document.createDocumentFragment()

    @events.forEach (event, index) ->
     if event.category
       categories.push event.category

    _.chain(categories).flattenDeep().uniq().value().forEach (category, index) ->
      if selectedCategoryArray.indexOf(category) is -1
        selectedCategory.others.push category

    for key, value of selectedCategory
      $fragment.append categoryTemplate {heading: key, categories: value}

    $fragment.appendTo @$categories

  filteringByCategory: ->
    switch @$categoryOrder.find('select').val()
      when 'or'
        @filteringByOr()
      when 'and'
        @filteringByAnd()

  filteringByOr: ->
    showCategories = []
    events = []

    @$categories.find('input:checked').each (index, el) ->
      showCategories.push $(el).val()

    @events.forEach (event) ->
      mergeCategory = event.category.concat showCategories
      if _.uniq(mergeCategory).length < event.category.length + showCategories.length
        events.push event

    @renderEvents events

  filteringByAnd: ->
    showCategories = []
    events = []

    checked = @$categories.find('input:checked')

    checked.each (index, el) ->
      showCategories.push $(el).val()

    @events.forEach (event) ->
      mergeCategory = event.category.concat showCategories
      if _.uniq(mergeCategory).length is event.category.length + showCategories.length - checked.length
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
        ev.left = ((Math.abs(@startYear) + event.start_year) * @oneUnitYearWith / @yearUnit) + 'px'
        ev.wikipedia = event.wikipedia || ''
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

new Timeline()
