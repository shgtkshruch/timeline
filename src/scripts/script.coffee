class Timeline
  constructor: ->

    @oneYearWith = 170
    @yearUnit = 10

    @$body =  $ '#timeline'
    @$years = $ '#timelineYears'
    @$events = $ '#timelineEvents'

    @renderYears()
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

  renderYears: ->
    @$years.empty()
    i = 0
    while i <= 100
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
    @fetch()

  fetch: ->
    @$events.empty()
    $.ajax
      url: 'data/timeline.json'
      success: (data, status, xhr) =>
        data.events.forEach (d) =>
          $ '<div></div>'
            .addClass 'timeline__event'
            .css
              top: '0'
              left: (d.start_year * @oneYearWith / @yearUnit) + 'px'
            .text d.text
            .appendTo @$events

new Timeline()
