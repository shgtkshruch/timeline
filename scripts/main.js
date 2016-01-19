(function() {
  var Timeline;

  Timeline = (function() {
    function Timeline() {
      this.$ruledLines = $('#timelineRuledLines');
      this.$years = $('#timelineYears');
      this.$events = $('#timelineEvents');
      this.$lightbox = $('#timelineLightbox');
      this.$categories = $('#timelineCategory');
      this.$sortOrder = $('#sortOrder');
      this.$arrangeOrder = $('#arrangeOrder');
      this.$lightboxClose = $('#lightboxClose');
      this.showLightboxId = '';
      this.$fragment = $(document.createDocumentFragment());
      this.setEvents();
      this.fetch();
    }

    Timeline.prototype.setEvents = function() {
      $('#controllerPlus').click((function(_this) {
        return function() {
          var nowYear;
          nowYear = _this.getNowYear();
          if (_this.oneUnitYearWidth < 10) {
            _this.oneUnitYearWidth++;
          } else {
            _this.oneUnitYearWidth += 10;
          }
          _this.renderRuledLine();
          _this.filteringByCategory();
          return _this.scrollWindow(nowYear);
        };
      })(this));
      $('#controllerMinus').click((function(_this) {
        return function() {
          var nowYear;
          nowYear = _this.getNowYear();
          if (_this.oneUnitYearWidth === 1) {
            return;
          } else if ((_this.oneUnitYearWidth - 10) <= 0) {
            _this.oneUnitYearWidth--;
          } else {
            _this.oneUnitYearWidth -= 10;
          }
          _this.renderRuledLine();
          _this.filteringByCategory();
          return _this.scrollWindow(nowYear);
        };
      })(this));
      this.$events.on('click', '.event', (function(_this) {
        return function(event) {
          return _this.getWikipediaText(event);
        };
      })(this));
      this.$lightboxClose.click((function(_this) {
        return function() {
          $('html').css({
            overflow: 'initial'
          });
          return _this.$lightbox.fadeOut(400, function() {
            return $(this).find('.lightbox__item').remove();
          });
        };
      })(this));
      this.$categories.on('change', (function(_this) {
        return function(event) {
          if ($(event.target).parents(_this.$arrangeOrder).is(_this.$arrangeOrder)) {
            return _this.rearrangingByOrder();
          } else {
            return _this.filteringByCategory();
          }
        };
      })(this));
      return $(window).scroll((function(_this) {
        return function() {
          return _this.$years.css({
            left: $(window).scrollLeft() * -1
          });
        };
      })(this));
    };

    Timeline.prototype.getNowYear = function() {
      return ($(window).scrollLeft() + $(window).width() / 2) * this.yearUnit / this.oneUnitYearWidth;
    };

    Timeline.prototype.scrollWindow = function(nowYear) {
      return $(window).scrollLeft(nowYear * this.oneUnitYearWidth / this.yearUnit - $(window).width() / 2);
    };

    Timeline.prototype.getWikipediaText = function(event) {
      var $el, text, url;
      $el = $(event.target).closest('.event');
      text = $el.data('wikipedia') || $el.find('.event__text').text();
      url = ['https://jp.wikipedia.org/w/api.php?', 'action=query', '&format=json', '&prop=extracts', '&exintro=', '&explaintext=', '&redirects=', '&titles=', text].join('');
      return $.ajax({
        url: url,
        dataType: 'jsonp',
        success: (function(_this) {
          return function(data, status, xhr) {
            var $lightboxInner, content, p, padding, pageId;
            pageId = Object.keys(data.query.pages)[0];
            content = pageId !== '-1' ? data.query.pages[pageId].extract : 'Wikipediaに記事がありませんでした。';
            $lightboxInner = $('#lightboxInner');
            padding = 20;
            p = $('<p></p>').addClass('lightbox__item').text(content);
            _this.$lightbox.css({
              top: $(window).scrollTop(),
              left: $(window).scrollLeft()
            }).find($lightboxInner).append(p).end().fadeIn();
            $('html').css({
              overflow: 'hidden'
            });
            return _this.$lightboxClose.css({
              top: $lightboxInner.position().top + padding + 'px',
              left: $lightboxInner.position().left + $lightboxInner.outerWidth() - padding + 'px'
            });
          };
        })(this)
      });
    };

    Timeline.prototype.fetch = function() {
      return $.ajax({
        url: 'data/timeline.json',
        success: (function(_this) {
          return function(data, status, xhr) {
            _this.events = data.events;
            _this.oneUnitYearWidth = parseInt(data.config.oneUnitYearWidth, 10 || 100);
            _this.yearUnit = parseInt(data.config.yearUnit, 10 || 10);
            _this.startYear = parseInt(data.config.start_year, 10);
            _this.endYear = parseInt(data.config.end_year, 10);
            _this.renderRuledLineFirst();
            _this.renderEventsFirst();
            return _this.renderCategories();
          };
        })(this)
      });
    };

    Timeline.prototype.renderRuledLineFirst = function() {
      var i, ruledLineTemplate;
      ruledLineTemplate = _.template($('#ruledLine-template').text());
      i = this.startYear;
      while (i <= this.endYear) {
        if (i % this.yearUnit === 0) {
          this.$fragment.append(ruledLineTemplate({
            width: this.oneUnitYearWidth + 'px'
          }));
        }
        i++;
      }
      this.$fragment.appendTo(this.$ruledLines);
      return this.renderYearsFirst();
    };

    Timeline.prototype.renderYearsFirst = function() {
      var i, year, yearTemplate;
      yearTemplate = _.template($('#year-template').text());
      i = this.startYear;
      while (i <= this.endYear) {
        if (i % this.yearUnit === 0) {
          year = {};
          year.width = this.oneUnitYearWidth + 'px';
          year.num = i % 100 === 0 ? i : i.toString().match(/\d{2}$/);
          this.$fragment.append(yearTemplate(year));
        }
        i++;
      }
      this.$fragment.appendTo(this.$years);
      return this.adjustOverlapYears();
    };

    Timeline.prototype.renderRuledLine = function() {
      $('.timeline__ruledLine').css({
        width: this.oneUnitYearWidth + 'px',
        visibility: 'visible'
      });
      return this.renderYears();
    };

    Timeline.prototype.renderYears = function() {
      $('.timeline__year').css({
        width: this.oneUnitYearWidth + 'px'
      }).children().show();
      return this.adjustOverlapYears();
    };

    Timeline.prototype.adjustOverlapYears = function() {
      var $timelineRuledLine, i, results, scale;
      $timelineRuledLine = $('.timeline__ruledLine');
      scale = [2, 5, 10, 100, 1000];
      i = 0;
      results = [];
      while (this.isOverlapYears()) {
        $timelineRuledLine.css({
          visibility: 'hidden'
        });
        $('.timeline__yearNum').hide().each(function(index, el) {
          var $el;
          $el = $(el);
          if (($el.text() / 10) % scale[i] === 0) {
            $el.show();
            return $timelineRuledLine.eq(index).css({
              visibility: 'visible'
            });
          }
        });
        results.push(i++);
      }
      return results;
    };

    Timeline.prototype.isOverlapYears = function() {
      var $prevElement, isOverlap;
      isOverlap = false;
      $prevElement = '';
      $('.timeline__yearNum').filter(':visible').each(function(index, el) {
        var $el;
        if (isOverlap) {
          return;
        }
        $el = $(el);
        if (index === 0) {
          $prevElement = $el;
          return;
        }
        if ($el.offset().left < $prevElement.offset().left + $prevElement.outerWidth()) {
          isOverlap = true;
        }
        return $prevElement = $el;
      });
      return isOverlap;
    };

    Timeline.prototype.renderCategories = function() {
      var $category, categories, categoryTemplate, key, selectedCategory, selectedCategoryArray, value;
      categories = [];
      selectedCategory = {
        kind: ['age', 'countory', 'event', 'human'],
        region: ['america', 'arab', 'china', 'egypt', 'europe', 'india', 'japan', 'russia'],
        occupation: ['art', 'architecture', 'economy', 'literature', 'politics', 'music', 'religion', 'scholar', 'science'],
        others: []
      };
      selectedCategoryArray = _.chain(selectedCategory).values().flatten().value();
      $category = $('#category');
      categoryTemplate = _.template($('#category-template').text());
      this.events.forEach(function(event, index) {
        if (event.category) {
          return categories.push(event.category);
        }
      });
      _.chain(categories).flattenDeep().uniq().value().forEach(function(category, index) {
        if (selectedCategoryArray.indexOf(category) === -1) {
          return selectedCategory.others.push(category);
        }
      });
      for (key in selectedCategory) {
        value = selectedCategory[key];
        this.$fragment.append(categoryTemplate({
          heading: key,
          categories: value
        }));
      }
      return this.$fragment.appendTo($category);
    };

    Timeline.prototype.filteringByCategory = function() {
      var checked, showCategories;
      showCategories = [];
      checked = this.$categories.find('input:checked');
      checked.each(function(index, el) {
        return showCategories.push($(el).val());
      });
      if (checked.length === 0) {
        $('.event').hide();
        this.extendYearAxis();
        return;
      }
      switch (this.$sortOrder.find('select').val()) {
        case 'and':
          return this.filteringByAnd(showCategories);
        case 'or':
          return this.filteringByOr(showCategories);
      }
    };

    Timeline.prototype.filteringByAnd = function(showCategories) {
      var events;
      events = [];
      $('.event').each(function(index, event) {
        var eventCategory, mergeCategory;
        eventCategory = $(event).data('category').split(',');
        mergeCategory = eventCategory.concat(showCategories);
        if (_.uniq(mergeCategory).length === eventCategory.length) {
          return events.push(event);
        }
      });
      return this.renderEvents(events);
    };

    Timeline.prototype.filteringByOr = function(showCategories) {
      var events;
      events = [];
      $('.event').each(function(index, event) {
        var eventCategory, mergeCategory;
        eventCategory = $(event).data('category').split(',');
        mergeCategory = eventCategory.concat(showCategories);
        if (_.uniq(mergeCategory).length < eventCategory.length + showCategories.length) {
          return events.push(event);
        }
      });
      return this.renderEvents(events);
    };

    Timeline.prototype.renderEventsFirst = function() {
      var eventTemplate;
      eventTemplate = _.template($('#event-template').text());
      _.chain(this.events).sortBy(function(n) {
        if (n.start_year === '?') {
          return parseInt(n.end_year, 10) - 50;
        } else {
          return parseInt(n.start_year, 10);
        }
      }).value().forEach((function(_this) {
        return function(event, index) {
          var endYearForPeriod, endYearForWidth, ev, startYearForPeriod, startYearForWidth;
          if (event.start_year === '?') {
            startYearForWidth = parseInt(event.end_year, 10) - 50;
            startYearForPeriod = '?';
          } else {
            startYearForWidth = startYearForPeriod = parseInt(event.start_year, 10);
          }
          if (event.end_year === '?') {
            endYearForWidth = parseInt(event.start_year, 10) + 50;
            endYearForPeriod = '?';
          } else if (event.end_year === '-') {
            endYearForWidth = parseInt(event.start_year, 10) + 50;
            endYearForPeriod = '-';
          } else {
            endYearForWidth = endYearForPeriod = parseInt(event.end_year, 10);
          }
          ev = {};
          ev.startYear = startYearForWidth;
          ev.endYear = endYearForWidth;
          ev.left = ((_this.startYear * -1 + startYearForWidth) * _this.oneUnitYearWidth / _this.yearUnit) + 'px';
          ev.wikipedia = event.wikipedia || '';
          ev.category = event.category;
          ev.timeWidth = ((endYearForWidth - startYearForWidth) * _this.oneUnitYearWidth / _this.yearUnit) + 'px';
          ev.period = startYearForPeriod + (endYearForPeriod ? ' ~ ' + endYearForPeriod : '');
          ev.text = event.text;
          return _this.$fragment.append(eventTemplate(ev));
        };
      })(this));
      this.$events.append(this.$fragment).find('.event').hide();
      return this.rearrangingByOrder();
    };

    Timeline.prototype.renderEvents = function(events) {
      $('.event').hide();
      events.forEach((function(_this) {
        return function(event) {
          var $event, endYear, startYear;
          $event = $(event);
          startYear = $event.data('startYear');
          endYear = $event.data('endYear');
          return $event.css({
            top: '0',
            left: ((_this.startYear * -1 + startYear) * _this.oneUnitYearWidth / _this.yearUnit) + 'px'
          }).children('.event__time').css({
            width: ((endYear - startYear) * _this.oneUnitYearWidth / _this.yearUnit) + 'px'
          }).end().show();
        };
      })(this));
      return this.rearrangingByOrder();
    };

    Timeline.prototype.rearrangingByOrder = function() {
      switch (this.$arrangeOrder.find('select').val()) {
        case 'masonry':
          return this.rearrangingByMasonry();
        case 'waterfall':
          return this.rearrangingByWaterfall();
      }
    };

    Timeline.prototype.rearrangingByWaterfall = function() {
      var leftEvents;
      leftEvents = [];
      $('.event').filter(':visible').each(function(index, el) {
        var $el;
        $el = $(el);
        $el.css({
          top: $el.outerHeight() * index
        });
        return leftEvents.push({
          $el: $el
        });
      });
      return this.extendYearAxis(leftEvents);
    };

    Timeline.prototype.rearrangingByMasonry = function() {
      var leftEvents;
      leftEvents = [];
      $('.event').filter(':visible').each(function(index, el) {
        var $el, loopEnd;
        $el = $(el);
        loopEnd = false;
        if (index === 0) {
          return leftEvents.push({
            row: $el.position().top,
            $el: $el
          });
        } else {
          return leftEvents.forEach(function(leftEvent, index2) {
            if (loopEnd) {
              return;
            }
            if ($el.offset().left > leftEvent.$el.offset().left + leftEvent.$el.outerWidth()) {
              loopEnd = true;
              $el.css({
                top: leftEvent.row
              });
              return leftEvents.splice(index2, 1, {
                row: $el.position().top,
                $el: $el
              });
            } else {
              if (index2 === leftEvents.length - 1) {
                $el.css({
                  top: leftEvent.row + $el.outerHeight()
                });
                return leftEvents.push({
                  row: $el.position().top,
                  $el: $el
                });
              }
            }
          });
        }
      });
      return this.extendYearAxis(leftEvents);
    };

    Timeline.prototype.extendYearAxis = function(leftEvents) {
      var last;
      last = _.last(leftEvents);
      if (last === void 0 || last.$el.offset().top + last.$el.outerHeight() < $(window).height()) {
        return this.$ruledLines.css({
          height: '100vh'
        });
      } else {
        return this.$ruledLines.css({
          height: last.$el.offset().top + last.$el.outerHeight() + 'px'
        });
      }
    };

    return Timeline;

  })();

  new Timeline();

}).call(this);

(function() {
  $('#intro').on('click', function() {
    return introJs().setOptions({
      steps: [
        {
          element: '#category',
          intro: '見たいカテゴリーを選択してください。<br/>ex.文学の人を見たい場合は、「Human」と「Literature」をチェックしてください。',
          position: 'right'
        }, {
          element: '#sortOrder',
          intro: '選んだカテゴリーの検索ルールを選択してください。<br/>and検索とor検索ができます。'
        }, {
          element: '#arrangeOrder',
          intro: '要素を年表に並べる時のルールを選択してください。<br/>詰めて並べるmasonryと、上から順に並べるwaterfallが選べます。'
        }, {
          element: '#timelineController',
          intro: '拡大縮小はこちらからどうぞ。',
          position: 'left'
        }, {
          intro: '横スクロールをして年表を御覧ください。<br/>年表の要素をクリックするとWikipediaの情報が見れます。'
        }
      ],
      nextLabel: '次へ',
      prevLabel: '前へ',
      skipLabel: '終わる',
      doneLabel: '終わる',
      exitOnOverlayClick: false,
      showStepNumbers: false,
      showProgress: true,
      scrollToElement: true,
      disableInteraction: false
    }).start();
  });

}).call(this);
