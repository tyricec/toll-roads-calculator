describe('tollroads calculator page', ->
  startPoint = element(By.model('map.local.route.start'))
  endPoint = element(By.model('map.local.route.end'))
  pointOptions = element.all(By.options('marker as marker.displayName for marker in map.local.startPoints'))
  endOptions = element.all(By.options('marker as marker.displayName for marker in map.local.displayPoints'))
  getRateBtn = element(By.buttonText('Find Your Toll'))
  axelSelections = element.all(By.model('map.local.route.axles'))
  paymentTypes = element.all(By.model('map.local.route.type'))

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
    expect(pointOptions.count()).toEqual(9)
    pointOptions.each((element, index) ->
      element.click()
      expect(startPoint.$('option:checked').getText()).toEqual(element.getText())
    )
  )
  it('should switch end options depending on start point options', ->
    expect(endOptions.count()).toEqual(9)
    optionData = pointOptions.map((element, index) -> 
      checkExitsMatch = (cond) ->
        endOptions.map( (element, index) -> cond(element) if index > 0 )
      element.click()
      if index is not 0
        expect(endOptions.count()).not.toBe(startOptions.count())
      index = (9 + index) % 9
      return false if index is 0
      element.getText().then( (result) ->
        if (/73/).test(result)
          checkExitsMatch( (element) -> 
            expect(element.getText()).toMatch(/73/)
          )
        else
          checkExitsMatch( (element) -> 
            expect(element.getText()).not.toMatch(/73/)
          )
      )
    )
  )

  it('should update the rates on the page', ->
    off_peak = element(By.binding('map.local.route.rateObj.rates.off_peak'))
#    weekend = element(By.binding('map.local.route.rateObj.rates.weekend'))
    axles = element(By.binding('map.local.route.rateObj.axles'))
    payment = element(By.binding('map.local.route.rateObj.payment'))
    start = element(By.binding('map.local.route.rateObj.start'))
    end = element(By.binding('map.local.route.rateObj.end'))

    pointOptions.each( (startElement, index) ->
      if index < 2 and index > 0
        startElement.click()
        endOption = endOptions.get(index + 3)
        endOption.click()
        axelSelections.each( (element, axelIndex) ->
          element.click()
          paymentTypes.each( (element, index) ->
            element.click()
            getRateBtn.click()
            expect(off_peak.getText()).toMatch(new RegExp(axelIndex + index + 1))
#            expect(weekend.getText()).toMatch(new RegExp(axelIndex + index + 1))
            expect(payment.getText()).toMatch(element.getText())
            expect(start.getText()).toMatch(new RegExp(startElement.getText()))
            expect(end.getText()).toMatch(new RegExp(endOption.getText()))
          )
        )
    )
  )

)
