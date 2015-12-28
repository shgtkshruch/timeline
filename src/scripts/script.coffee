class Timeline
  constructor: ->

    @$years = $ '#timelineYears'
    @$events = $ '#timelineEvents'
    @$lightbox = $ '#timelineLightbox'
    @$categories = $ '#timelineCategory'
    @$categoryOrder = $ '#categoryOrder'
    @$lightboxClose = $ '#lightboxClose'

    @showLightboxId = ''
    @borderStyle = '1px dashed rgba(255, 255, 255, 0.3)'

    @setEvents()
    @fetch()

  setEvents: ->
    $ '#controllerPlus'
      .click (e) =>
        nowYear = @getNowYear()
        if @oneUnitYearWidth < 10
          @oneUnitYearWidth++
        else
          @oneUnitYearWidth += 10
        @renderYears()
        @filteringByCategory()
        @scrollWindow nowYear

    $ '#controllerMinus'
      .click (e) =>
        nowYear = @getNowYear()
        if @oneUnitYearWidth is 1
          return
        else if (@oneUnitYearWidth - 10) <= 0
          @oneUnitYearWidth--
        else
          @oneUnitYearWidth -= 10
        @renderYears()
        @filteringByCategory()
        @scrollWindow nowYear

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
              top: $(window).scrollTop()
              left: $(window).scrollLeft()
            .find $lightboxInner
              .append p
              .end()
            .fadeIn()

          $ 'html'
            .css
              overflow: 'hidden'

          @$lightboxClose.css
            top: $lightboxInner.position().top + padding + 'px'
            left: $lightboxInner.position().left + $lightboxInner.outerWidth() - padding + 'px'

    @$lightboxClose.click (e) =>
      $ 'html'
        .css
          overflow: 'initial'
      @$lightbox.fadeOut 400, ->
        $(@)
          .find '.lightbox__item'
          .remove()

    @$categories.on 'change', (e) =>
      @filteringByCategory()

  getNowYear: ->
    return ($(window).scrollLeft() + $(window).width() / 2) * @yearUnit / @oneUnitYearWidth

  scrollWindow: (nowYear) ->
    $(window).scrollLeft nowYear * @oneUnitYearWidth / @yearUnit - $(window).width() / 2

  fetch: ->
    $.ajax
      url: 'data/timeline.json'
      success: (data, status, xhr) =>
        @events = data.events
        @oneUnitYearWidth = parseInt data.config.oneUnitYearWidth, 10 || 100
        @yearUnit = parseInt data.config.yearUnit, 10 || 10
        @startYear = parseInt data.config.start_year, 10
        @endYear = parseInt data.config.end_year, 10

        @renderYearsFirst()
        @renderEventsFirst()
        @renderCategories()

  renderYearsFirst: ->
    $fragment = $ document.createDocumentFragment()
    yearTemplate = _.template $('#year-template').text()

    i = @startYear
    while i <= @endYear
      if i % @yearUnit is 0
        year = {}
        year.width = @oneUnitYearWidth + 'px'
        year.num = if i % 100 is 0 then i else i.toString().match(/\d{2}$/)
        $fragment.append yearTemplate year
      i++

    $fragment.appendTo @$years

    @adjustOverlapYears()

  renderYears: ->
    $ '.timeline__year'
      .css
        width: @oneUnitYearWidth + 'px'
        'border-left': @borderStyle
      .children()
      .show()

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
        .each (index, el) =>
          $el = $ el
          if ($el.text() / 10) % scale[i] is 0
            $el
              .show()
              .parent()
              .css
                'border-left': @borderStyle
      i++

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
      kind: ['age', 'countory', 'event', 'human']
      region: ['america', 'arab', 'china', 'egypt', 'europe', 'india', 'japan']
      occupation: ['art','economy', 'politics', 'religion', 'scholar', 'science']
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
    checked = @$categories.find('input:checked')
    if checked.length is 0
      @$events.empty()
      return

    switch @$categoryOrder.find('select').val()
      when 'and'
        @filteringByAnd checked
      when 'or'
        @filteringByOr checked

  filteringByAnd: (checked) ->
    showCategories = []
    events = []

    checked.each (index, el) ->
      showCategories.push $(el).val()

    @events.forEach (event) ->
      mergeCategory = event.category.concat showCategories
      if _.uniq(mergeCategory).length is event.category.length + showCategories.length - checked.length
        events.push event

    @renderEvents events

  filteringByOr: (checked) ->
    showCategories = []
    events = []

    checked.each (index, el) ->
      showCategories.push $(el).val()

    @events.forEach (event) ->
      mergeCategory = event.category.concat showCategories
      if _.uniq(mergeCategory).length < event.category.length + showCategories.length
        events.push event

    @renderEvents events

  renderEventsFirst: ->
    @renderEvents @events

  renderEvents: (events) ->
    $fragment = $ document.createDocumentFragment()
    eventTemplate = _.template $('#event-template').text()

    @$events.empty()

    _.chain(events)
      .sortBy (n) ->
        if n.start_year is '?'
          parseInt(n.end_year, 10) - 50
        else
          parseInt n.start_year, 10
      .value()
      .forEach (event, index) =>

        if event.start_year is '?'
          startYearForWidth = parseInt(event.end_year, 10) - 50
          startYearForPeriod = '?'
        else
          startYearForWidth = startYearForPeriod = parseInt event.start_year, 10

        if event.end_year is '?'
          endYearForWidth = parseInt(event.start_year, 10) + 50
          endYearForPeriod = '?'
        else
          endYearForWidth = endYearForPeriod = parseInt event.end_year, 10

        ev = {}
        ev.left = ((@startYear * -1 + startYearForWidth) * @oneUnitYearWidth / @yearUnit) + 'px'
        ev.wikipedia = event.wikipedia || ''
        ev.timeWidth = ((endYearForWidth - startYearForWidth) * @oneUnitYearWidth / @yearUnit) + 'px'
        ev.period = startYearForPeriod + if endYearForPeriod then ' ~ ' + endYearForPeriod else ''
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
          leftEvents.push {row: $el.position().top, $el: $el}
        else
          leftEvents.forEach (leftEvent, index2) ->
            return if loopEnd
            if $el.offset().left > leftEvent.$el.offset().left + leftEvent.$el.outerWidth()
              loopEnd = true
              leftEvents.splice index2, 1, {row: $el.position().top, $el: $el}
            else
              $el.css
                top: leftEvent.row + $el.outerHeight()
              if index2 is leftEvents.length - 1
                leftEvents.push {row: $el.position().top, $el: $el}

    @extendYearAxis leftEvents

  extendYearAxis: (leftEvents) ->
    last = _.last(leftEvents)
    if last is undefined or last.$el.offset().top + last.$el.outerHeight() < $(window).height()
      @$years
        .css
          height: '100vh'
    else
      @$years
        .css
          height: last.$el.offset().top + last.$el.outerHeight() + 'px'

new Timeline()
