class Timeline
  constructor: ->

    @$ruledLines = $ '#timelineRuledLines'
    @$years = $ '#timelineYears'
    @$events = $ '#timelineEvents'
    @$lightbox = $ '#timelineLightbox'
    @$categories = $ '#timelineCategory'
    @$sortOrder = $ '#sortOrder'
    @$arrangeOrder = $ '#arrangeOrder'
    @$lightboxClose = $ '#lightboxClose'

    @showLightboxId = ''
    @$fragment = $ document.createDocumentFragment()

    @setEvents()
    @fetch()

  setEvents: ->
    $ '#controllerPlus'
      .click =>
        nowYear = @getNowYear()
        if @oneUnitYearWidth < 10
          @oneUnitYearWidth++
        else
          @oneUnitYearWidth += 10
        @renderRuledLine()
        @filteringByCategory()
        @scrollWindow nowYear

    $ '#controllerMinus'
      .click =>
        nowYear = @getNowYear()
        if @oneUnitYearWidth is 1
          return
        else if (@oneUnitYearWidth - 10) <= 0
          @oneUnitYearWidth--
        else
          @oneUnitYearWidth -= 10
        @renderRuledLine()
        @filteringByCategory()
        @scrollWindow nowYear

    @$events.on 'click', '.event', (event) =>
      @getWikipediaText event

    @$lightboxClose.click =>
      $('html').css overflow: 'initial'

      @$lightbox.fadeOut 400, ->
        $(@).find('.lightbox__item').remove()

    @$categories.on 'change', (event) =>
      if $(event.target).parents(@$arrangeOrder).is(@$arrangeOrder)
        @rearrangingByOrder()
      else
        @filteringByCategory()

    $(window).scroll =>
      @$years.css left: $(window).scrollLeft() * -1

  getNowYear: ->
    return ($(window).scrollLeft() + $(window).width() / 2) * @yearUnit / @oneUnitYearWidth

  scrollWindow: (nowYear) ->
    $(window).scrollLeft nowYear * @oneUnitYearWidth / @yearUnit - $(window).width() / 2

  getWikipediaText: (event) ->
    $el = $(event.target).closest('.event')
    text = $el.data('wikipedia') || $el.find('.event__text').text()
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

        $('html').css overflow: 'hidden'

        @$lightboxClose.css
          top: $lightboxInner.position().top + padding + 'px'
          left: $lightboxInner.position().left + $lightboxInner.outerWidth() - padding + 'px'

  fetch: ->
    $.ajax
      url: 'data/timeline.json'
      success: (data, status, xhr) =>
        @events = data.events
        @oneUnitYearWidth = parseInt data.config.oneUnitYearWidth, 10 || 100
        @yearUnit = parseInt data.config.yearUnit, 10 || 10
        @startYear = parseInt data.config.start_year, 10
        @endYear = parseInt data.config.end_year, 10

        @renderRuledLineFirst()
        @renderEventsFirst()
        @renderCategories()

  renderRuledLineFirst: ->
    ruledLineTemplate = _.template $('#ruledLine-template').text()

    i = @startYear
    while i <= @endYear
      if i % @yearUnit is 0
        @$fragment.append ruledLineTemplate {width: @oneUnitYearWidth + 'px'}
      i++

    @$fragment.appendTo @$ruledLines

    @renderYearsFirst()

  renderYearsFirst: ->
    yearTemplate = _.template $('#year-template').text()

    i = @startYear
    while i <= @endYear
      if i % @yearUnit is 0
        year = {}
        year.width = @oneUnitYearWidth + 'px'
        year.num = if i % 100 is 0 then i else i.toString().match(/\d{2}$/)
        @$fragment.append yearTemplate year
      i++

    @$fragment.appendTo @$years

    @adjustOverlapYears()

  renderRuledLine: ->
    $ '.timeline__ruledLine'
      .css
        width: @oneUnitYearWidth + 'px'
        visibility: 'visible'

    @renderYears()

  renderYears: ->
    $ '.timeline__year'
      .css width: @oneUnitYearWidth + 'px'
      .children()
      .show()

    @adjustOverlapYears()

  adjustOverlapYears: ->
    $timelineRuledLine = $ '.timeline__ruledLine'
    scale = [2, 5, 10, 100, 1000]
    i = 0
    while @isOverlapYears()
      $timelineRuledLine.css visibility: 'hidden'
      $ '.timeline__yearNum'
        .hide()
        .each (index, el) ->
          $el = $ el
          if ($el.text() / 10) % scale[i] is 0
            $el.show()
            $timelineRuledLine.eq(index).css visibility: 'visible'
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
      region: ['america', 'arab', 'china', 'egypt', 'europe', 'india', 'japan', 'russia']
      occupation: ['art', 'architecture', 'economy', 'literature', 'politics', 'music', 'religion', 'scholar', 'science']
      others: []
    selectedCategoryArray = _.chain(selectedCategory).values().flatten().value()

    categoryTemplate = _.template $('#category-template').text()

    @events.forEach (event, index) ->
     if event.category
       categories.push event.category

    _.chain(categories).flattenDeep().uniq().value().forEach (category, index) ->
      if selectedCategoryArray.indexOf(category) is -1
        selectedCategory.others.push category

    for key, value of selectedCategory
      @$fragment.append categoryTemplate {heading: key, categories: value}

    @$fragment.appendTo @$categories

  filteringByCategory: ->
    showCategories = []
    checked = @$categories.find('input:checked')
    checked.each (index, el) ->
      showCategories.push $(el).val()

    if checked.length is 0
      $('.event').hide()
      @extendYearAxis()
      return

    switch @$sortOrder.find('select').val()
      when 'and'
        @filteringByAnd showCategories
      when 'or'
        @filteringByOr showCategories

  filteringByAnd: (showCategories) ->
    events = []

    $ '.event'
      .each (index, event) ->
        eventCategory = $(event).data('category').split(',')
        mergeCategory = eventCategory.concat showCategories
        if _.uniq(mergeCategory).length is eventCategory.length
          events.push event

    @renderEvents events

  filteringByOr: (showCategories) ->
    events = []

    $ '.event'
      .each (index, event) ->
        eventCategory = $(event).data('category').split(',')
        mergeCategory = eventCategory.concat showCategories
        if _.uniq(mergeCategory).length < eventCategory.length + showCategories.length
          events.push event

    @renderEvents events

  renderEventsFirst: ->
    eventTemplate = _.template $('#event-template').text()

    _.chain(@events)
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
        ev.startYear = startYearForWidth
        ev.endYear = endYearForWidth
        ev.left = ((@startYear * -1 + startYearForWidth) * @oneUnitYearWidth / @yearUnit) + 'px'
        ev.wikipedia = event.wikipedia || ''
        ev.category = event.category
        ev.timeWidth = ((endYearForWidth - startYearForWidth) * @oneUnitYearWidth / @yearUnit) + 'px'
        ev.period = startYearForPeriod + if endYearForPeriod then ' ~ ' + endYearForPeriod else ''
        ev.text = event.text
        @$fragment.append eventTemplate ev

    @$events.append(@$fragment).find('.event').hide()

    @rearrangingByOrder()

  renderEvents: (events) ->
    $('.event').hide()

    events.forEach (event) =>
      $event = $ event
      startYear = $event.data('startYear')
      endYear = $event.data('endYear')
      $event
        .css
          top: '0'
          left: ((@startYear * -1 + startYear) * @oneUnitYearWidth / @yearUnit) + 'px'
        .children '.event__time'
          .css
            width: ((endYear - startYear) * @oneUnitYearWidth / @yearUnit) + 'px'
          .end()
        .show()

    @rearrangingByOrder()

  rearrangingByOrder: ->
    switch @$arrangeOrder.find('select').val()
      when 'masonry'
        @rearrangingByMasonry()
      when 'waterfall'
        @rearrangingByWaterfall()

  rearrangingByWaterfall: ->
    leftEvents = []
    $ '.event'
      .filter ':visible'
      .each (index, el) ->
        $el = $ el
        $el.css top: $el.outerHeight() * index
        leftEvents.push {$el: $el}

    @extendYearAxis leftEvents

  rearrangingByMasonry: ->
    leftEvents = []
    $ '.event'
      .filter ':visible'
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
              $el.css top: leftEvent.row
              leftEvents.splice index2, 1, {row: $el.position().top, $el: $el}
            else
              if index2 is leftEvents.length - 1
                $el.css top: leftEvent.row + $el.outerHeight()
                leftEvents.push {row: $el.position().top, $el: $el}

    @extendYearAxis leftEvents

  extendYearAxis: (leftEvents) ->
    last = _.last(leftEvents)
    if last is undefined or last.$el.offset().top + last.$el.outerHeight() < $(window).height()
      @$ruledLines.css height: '100vh'
    else
      @$ruledLines.css height: last.$el.offset().top + last.$el.outerHeight() + 'px'

new Timeline()
