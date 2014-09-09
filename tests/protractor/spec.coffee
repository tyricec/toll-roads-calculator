describe('User goes to tollroads calculator page', ->
  startPoint = element(By.model('map.local.route.start'))
  endPoint = element(By.model('map.local.route.end'))
  fwy = element(By.model('map.local.route.fwy'))
  pointOptions = element.all(By.options('marker as marker.displayName for marker in map.local.startDisplayOpts'))
  endOptions = element.all(By.options('marker as marker.displayName for marker in map.local.endDisplayOpts'))
  getRateBtn = element(By.buttonText('Calculate Your Toll'))
  axelSelections = element.all(By.model('map.local.route.axles'))
  paymentTypes = element.all(By.model('map.local.route.type'))

  beforeEach -> 
    browser.get('http://localhost:65513')
    browser.waitForAngular()

  it('and can see the title', ->
    expect(browser.getTitle()).toEqual('The Toll Roads | Toll Cost Calculator')
  )

  it('and should see default options', ->
    expect(startPoint.$('option:checked').getText()).toMatch(/select/gi)
    expect(startPoint.$('option:checked').getText()).toMatch(/select/gi)
  )

  it('and should be able to click each point to start with dropdown.', ->
    expect(pointOptions.count()).toEqual(7)
    pointOptions.each((element, index) ->
      element.click()
      expect(startPoint.$('option:checked').getText()).toEqual(element.getText())
    )
  )

  it('and should be able to see a switch between end options depending on start point options', ->
    browser.waitForAngular()
    expect(endOptions.count()).toEqual(7)
    currStartOption = pointOptions.get(1)
    currStartOption.click()
    expect(endOptions.count()).toEqual(6)
    fwy.all(By.tagName 'option').get(1).click()
    expect(endOptions.count()).toEqual(3)
    currStartOption = pointOptions.get(1)
    currStartOption.click()
    expect(endOptions.count()).toEqual(2)
  )

  it('and be able to get a rates on the page', ->
    off_peak = element(By.binding('map.local.route.rateObj.rates.off_peak'))
    axles = element(By.binding('map.local.route.rateObj.axles'))
    start = element(By.binding('map.local.route.rateObj.start'))
    end = element(By.binding('map.local.route.rateObj.end'))

    firstElement = pointOptions.get(1)
    firstElement.click()
    endOption = endOptions.get(3)
    endOption.click()
    axelSelections.first().click()
    paymentTypes.first().click()
    getRateBtn.click()
    expect(off_peak.getText()).toMatch(new RegExp(3))
  )

  it('and should be able to see adjustments when a rate has one.', ->
    descriptionIds = element.all(By.repeater('rate in map.local.route.rateObj.rates.peak').column('{{rate.descriptionIds}}'))
    descriptions = element.all(By.repeater('rate in map.local.route.rateObj.rates.peak').column('{{rate.description}}'))
    rates = element.all(By.repeater('rate in map.local.route.rateObj.rates.peak').column('{{rate.rate}}'))
    descriptionArray = ["Addition for 73", "Subtraction for 73"]
    adjustmentsArray = [0.25, -0.25]
    # Check Only Adjustment in table
    fwy.all(By.tagName 'option').get(1).click()
    pointOptions.get(1).click()
    endOptions.get(1).click()
    axelSelections.each( (axelElement, axelIndex) ->
      do -> 
        axelElement.click()
        getRateBtn.click()
        descriptionIds.each( (id) -> expect(id.getText()).toBe( Array(typeIndex + 1).join("*") ) )
        descriptions.each( (description, index) -> expect(description.getText()).toMatch(new RegExp(descriptionArray[index])) )
        rates.each( (rate, index) -> expect(rate.getText()).toMatch(1 + axelIndex + adjustmentsArray[index] ) )
    )
  )

  it('and should be able to click on a point on the map to select start and end.', ->
    off_peak = element(By.binding('map.local.route.rateObj.rates.off_peak'))
    element(By.css('div[title="1"]')).click()
    element(By.className('start-btn')).click()
    expect(startPoint.getText()).toMatch(/241 ENTRY\/EXIT/)
    element(By.css('div[title="10"]')).click()
    element(By.className('end-btn')).click()
    browser.actions().mouseDown().mouseUp().perform()
    expect(endPoint.$('option:checked').getText()).toMatch(/241 EXIT/)
    getRateBtn.click()
    browser.waitForAngular()
    expect(off_peak.getText()).toMatch(/3/)
  )

)