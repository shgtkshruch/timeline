class Timeline
  constructor: ->

    @$body =  $ '#timeline'
    @$years = $ '#timelineYears'
    @$events = $ '#timelineEvents'

    @fetch()
    @events()

  events: ->
    $ '#controllerPlus'
      .click (e) =>
        @oneUnitYearWith += 10
        @renderYears()

    $ '#controllerMinus'
      .click (e) =>
        @oneUnitYearWith -= 10
        @renderYears()

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
            .text i
            .end()
          .appendTo @$years
      i++
    @renderEvents()

  renderEvents: ->
    @$events.empty()
    @events.forEach (event) =>
      $ '<div></div>'
        .addClass 'timeline__event'
        .css
          top: '0'
          left: (event.start_year * @oneUnitYearWith / @yearUnit) + 'px'
        .text event.text
        .appendTo @$events
    @ajustOverlap()

  ajustOverlap: ->
    $prevItem = ''
    $ '.timeline__event'
      .each (index, el) ->
        if index is 0
          $prevItem = $ el
        else
          $el = $ el
          prevItemRightSidePosition = $prevItem.offset().left + $prevItem.outerWidth()
          nowItemLeftSidePosition = $el.offset().left
          if prevItemRightSidePosition > nowItemLeftSidePosition
            $el.css
              top: $prevItem.offset().top + $prevItem.outerHeight()
          $prevItem = $el

new Timeline()
