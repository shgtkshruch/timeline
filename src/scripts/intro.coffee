$ '#intro'
  .on 'click', ->
    introJs()
      .setOptions
        steps: [
          {
            element: '#category'
            intro: '見たいカテゴリーを選択してください。'
            position: 'right'
          }
          {
            element: '#sortOrder'
            intro: '選んだカテゴリーの検索ルールを選択してください。'
          }
          {
            element: '#arrangeOrder'
            intro: '要素を年表に並べる時のルールを選択してください。'
          }
          {
            element: '#timelineController'
            intro: '拡大縮小はこちらからどうぞ。'
            position: 'left'
          }
          {
            intro: '横スクロールをしてコンテンツを御覧ください。<br/>年表の要素をクリックするとWikipediaの情報が見れます'
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
