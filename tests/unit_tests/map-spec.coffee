describe 'map-controller', ->
  routeObjs = [
    {"route_id": '1', "route_name": "test1", "route_lat": 0, "route_long": 0, "route_type": "point", "route_point_type": "entry/exit", "route_fwy": 241},
    {"route_id": '2', "route_name": "test2", "route_lat": 0, "route_long": 0, "route_type": "point", "route_point_type": "entry", "route_fwy": 241},
    {"route_id": '3', "route_name": "test3", "route_lat": 0, "route_long": 0, "route_type": "point", "route_point_type": "exit", "route_fwy": 241},
    {"route_id": '4', "route_name": "test4", "route_lat": 0, "route_long": 0, "route_type": "point", "route_point_type": "entry/exit", "route_fwy": '73'},
    {"route_id": '5', "route_name": "test5", "route_lat": 0, "route_long": 0, "route_type": "plaza", "route_point_type": "null", "route_fwy": 241}
  ]

  scope = {}
  $httpBackend = {}
  mapController = {}
  infoController = {}
  points = []
  timeout = {}

  beforeEach module('mapApp')

  beforeEach inject (_$httpBackend_, $rootScope, $timeout, sharedProperties, $controller) -> 
      $httpBackend = _$httpBackend_
      timeout = $timeout
      $httpBackend.expectGET('php/routes.php?method=getRoutes').respond(200, routeObjs)
      scope = $rootScope.$new()
      mapController = $controller('mapController', {$scope: scope})
      
      $httpBackend.flush()
      
      scope.map.local.points.forEach (point) ->
        point.clickStart = () -> scope.map.local.start = @id
        point.clickEnd = () -> scope.map.local.end = @id
        point.model = point

      points = scope.map.local.points
      
      scope.map.local.route.fwy = "rest"
      scope.$apply()  
  
  it('should correctly place markers in correct models.', ->
    scope.map.local.route.fwy = "73"
    scope.$apply()
    expect(scope.map.local.points.length).toBe(1)
    scope.map.local.route.fwy = "rest"
    scope.$apply()
    expect(scope.map.local.points.length).toBe(3)
    expect(scope.map.local.startPoints.length).toBe(3)
    expect(scope.map.local.endPoints.length).toBe(3)
  ) 

  it('should set current marker focused when clicked.', ->
    scope.map.local.points.forEach (point) ->
      point.model = point
      point.onClick()
      expect(point.status).toBe("focused")
      # Check if the rest are default
      scope.map.local.points.forEach (point) -> expect(point.prevIcon).toMatch(new RegExp(point.status)) unless point.status is "focused"
  )

  it('should set marker back to original when info window is closed.', ->
    scope.map.local.points.forEach (point) ->
      scope.map.closeWindow()
      expect(point.prevIcon).toMatch(point.status)
  )

  it('should show start/end buttons based on the type of point.', ->
    points.forEach (point) ->
      point.model = point
      point.onClick()
      scope.$apply()
      if point.point_type isnt "exit"
        expect(scope.showStartBtn).toBe(true)
      if point.point_type isnt "entry"
        expect(scope.showEndBtn).toBe(true)
  )

  it('should have a button to switch the start and the end points', ->
    scope.map.local.route.start = points[0]
    scope.map.local.route.end = points[3]

    scope.map.switchPoints()
    expect(scope.map.local.route.start).toBe(points[3])
    expect(scope.map.local.route.end).toBe(points[0])
  )

  it('should swtich points if possible', ->
    scope.map.local.route.start = points[0]
    scope.map.switchPoints()
    expect(scope.map.local.route.start).toBeNull()
    scope.map.local.route.start = null
    scope.map.local.route.end = scope.map.local.points[0]
    scope.map.switchPoints()
    expect(scope.map.local.route.end).toBeNull()
  )

  it('should not switch points if not possible', ->
    scope.map.local.route.start = points[1]
    scope.map.switchPoints()
    expect(scope.map.local.route.start).toBe(points[1])
    scope.map.local.route.start = null
    #scope.map.local.route.end = points[2]
    #scope.map.switchPoints()
    #expect(scope.map.local.route.end).toBe(points[2])
  )

  it('should switch kml layers on fwy change', ->
    scope.map.local.route.fwy = "73"
    scope.$apply()
    expect(scope.map.showFwy73).toBe(true)
    expect(scope.map.showFwyRest).toBe(false)
    scope.map.local.route.fwy = "rest"
    scope.$apply()
    expect(scope.map.showFwy73).toBe(false)
    expect(scope.map.showFwyRest).toBe(true)
  )

  it('should not have more than one marker with a start icon whenever start changes.', ->
    points[0].model = points[0]
    points[1].model = points[1]
    points[0].onClick()
    scope.model = points[0].model
    scope.onStartClick()
    scope.$apply()
    expect(scope.map.local.route.start.id).toBe(points[0].id)
    points[0].onClick()
    points[1].onClick()
    scope.model = points[1].model
    scope.onStartClick()
    scope.$apply()
    expect(scope.map.local.route.start.id).toBe(points[1].id)
    expect(points[0].icon).toMatch(/inactive/)
    expect(points[1].icon).toMatch(/start/)
  )

  it('should not have more than one marker with a end icon whenever end changes.', ->
    points[0].model = points[0]
    points[2].model = points[2]
    points[0].onClick()
    scope.model = points[0].model
    scope.onEndClick()
    scope.$apply()
    expect(scope.map.local.route.end.id).toBe(points[0].id)
    points[0].onClick()
    points[2].onClick()
    scope.model = points[2].model
    scope.onEndClick()
    scope.$apply()
    expect(scope.map.local.route.end.id).toBe(points[2].id)
    expect(points[0].icon).toMatch(/inactive/)
    expect(points[2].icon).toMatch(/end/)
  )

  it('should set all markers inactive if freeway switch', ->
    points[0].model = points[0]
    points[0].onClick()
    scope.model = points[0].model
    scope.onStartClick()
    scope.$apply()
    expect(points[0].icon).toMatch(/start/)
    scope.map.local.route.fwy = '73'
    scope.$apply()
    expect(scope.map.local.route.start).toBeNull()
    scope.map.local.route.fwy = 'rest'
    scope.$apply()
    expect(points[0].icon).toMatch(/inactive/)
  )

  describe 'the start and end points', ->

    afterEach -> scope.map.local.route.start = 0; scope.map.local.route.end = 0

    it('should save be saved in route object when the start or end button is clicked', ->
      points.forEach (point) ->
        point.model = point
        point.onClick()
        scope.model = point.model
        if point.point_type isnt "exit"  
          scope.onStartClick()
          expect(scope.map.local.route.start.id).toBe(point.id)
        if point.point_type isnt "entry"
          if scope.map.local.route.start.id is point.id then isSwitch = true else isSwitch = false
          scope.onEndClick()
          expect(scope.map.local.route.end.id).toBe(point.id)
          if not isSwitch
            expect(scope.map.local.route.start.id).not.toBe(point.id)
          else
            expect(scope.map.local.route.start).toBeNull()
    )

    it('shouldn\'t reduce end options whenever end is changed.', ->
      origLength = scope.map.local.endDisplayOpts.length
      points.filter((point) -> point.point_type is "exit").forEach (point) ->
        point.model = point
        point.onClick()
        scope.model = point.model
        scope.onEndClick()
        expect(scope.map.local.endDisplayOpts.length).toBe(origLength)
    )

    it('should reduce start options whenever start is changed.', ->
      origLength = scope.map.local.points.length
      points.filter((point) -> point.point_type isnt "exit").forEach (point) ->
        point.model = point
        point.onClick()
        scope.model = point.model
        scope.onStartClick()
        expect(scope.map.local.endDisplayOpts.length).not.toBe(origLength)
    )
    