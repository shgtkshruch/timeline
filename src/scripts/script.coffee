class Timeline
  constructor: ->

    @oneYearWith = 170
    @yearUnit = 10

    @$body =  $ '#timeline'
    @$years = $ '#timelineYears'
    @$events = $ '#timelineEvents'

    @fetch()
    @events()

  events: ->
    $ '#controllerPlus'
      .click (e) =>
        @oneYearWith += 10
        @renderYears()

    $ '#controllerMinus'
      .click (e) =>
        @oneYearWith -= 10
        @renderYears()

  fetch: ->
    $.ajax
      url: 'data/timeline.json'
      success: (data, status, xhr) =>
        @data = data
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
            width: @oneYearWith + 'px'
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
    @data.events.forEach (d) =>
      $ '<div></div>'
        .addClass 'timeline__event'
        .css
          top: '0'
          left: (d.start_year * @oneYearWith / @yearUnit) + 'px'
        .text d.text
        .appendTo @$events

new Timeline()
