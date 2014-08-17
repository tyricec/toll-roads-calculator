describe('tollroads calculator page', ->
  startPoint = element(By.model('map.local.route.start'))
  endPoint = element(By.model('map.local.route.end'))
  pointOptions = element.all(By.options('marker as marker.name for marker in map.local.points'))
  endOptions = element.all(By.options('marker as marker.name for marker in map.local.displayPoints'))

  selectDropdownbyNum = (element, optionNum) ->
    if optionNum
      options = element.findElements(By.tagName('option')).then((options) ->
        options[optionNum].click()
      )
  
  beforeEach -> 
    browser.get('http://localhost:8000')
    browser.waitForAngular()


  it('should have a title', ->
    expect(browser.getTitle()).toEqual('The Toll Roads | Toll Cost Calculator')
  )

  it('should have default options', ->
    expect(startPoint.$('option:checked').getText()).toMatch(/select/gi)
    expect(startPoint.$('option:checked').getText()).toMatch(/select/gi)
  )

  it('should be able to click each point on start', ->
    expect(pointOptions.count()).toEqual(36)
    pointOptions.each((element, index) ->
      element.click()
      expect(startPoint.$('option:checked').getText()).toEqual(element.getText())
    )
  )
  it('should switch end options depending on start point options', ->
    expect(endOptions.count()).toEqual(36)
    optionData = pointOptions.map((element, index) -> 
      element.click()
      if index is not 0
        expect(endOptions.count()).not.toBe(startOptions.count())
      index = (19 + index) % 19
      index = 1 if index is 0
    )

  )
)
