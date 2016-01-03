$ '#intro'
  .on 'click', ->
    introJs()
      .setOptions
        steps: [
          {
            element: '#category'
            intro: '見たいカテゴリーを選択してください。<br/>ex.文学の人を見たい場合は、「Human」と「Literature」をチェックしてください。'
            position: 'right'
          }
          {
            element: '#sortOrder'
            intro: '選んだカテゴリーの検索ルールを選択してください。<br/>and検索とor検索ができます。'
          }
          {
            element: '#arrangeOrder'
            intro: '要素を年表に並べる時のルールを選択してください。<br/>詰めて並べるmarsonryと、上から順に並べるwaterfallが選べます。'
          }
          {
            element: '#timelineController'
            intro: '拡大縮小はこちらからどうぞ。'
            position: 'left'
          }
          {
            intro: '横スクロールをして年表を御覧ください。<br/>年表の要素をクリックするとWikipediaの情報が見れます。'
          }
        ]
        nextLabel: '次へ'
        prevLabel: '前へ'
        skipLabel: '終わる'
        doneLabel: '終わる'
        exitOnOverlayClick: false
        showStepNumbers: false
        showProgress: true
        scrollToElement: true
        disableInteraction: false
      .start()
