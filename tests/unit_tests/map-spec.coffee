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
    scope.map.local.route.end = points[1]

    scope.map.switchPoints()
    expect(scope.map.local.route.start).toBe(points[1])
    expect(scope.map.local.route.end).toBe(points[0])
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
            expect(scope.map.local.route.start.id).toBeUndefined()
    )

    it('should set all markers that aren\'t start or end to inactive.', ->
      points.filter((point) -> point.point_type isnt "exit").forEach (point) ->
        point.onClick()
        scope.model = point.model
        scope.onStartClick()
        points.filter((thisPoint) -> thisPoint isnt point).forEach (point) ->
          expect(point.status).toBe('inactive')
          expect(point.prevIcon).toMatch(new RegExp(point.status))

    )

    it('should have errors thrown if start and end functions are invoked without current marker having them.', ->
      points.filter((point) -> point.point_type is "entry").forEach (point) ->
        point.onClick()
        scope.model = point.model
        expect(scope.onStartClick).not.toThrow()
        expect(scope.onEndClick).toThrow()

      points.filter((point) -> point.point_type is "exit").forEach (point) ->
        point.onClick()
        scope.model = point.model
        expect(scope.onEndClick).not.toThrow()
        expect(scope.onStartClick).toThrow()
        
    )

    it('should set current marker to inactive if start is selected to be different independent of window.', ->
      points.forEach (point) ->
        point.onClick()
        scope.model = point.model
        scope.onStartClick() unless point.point_type is "exit"
        point.onClick()
        points.filter((thisPoint) -> thisPoint isnt point).forEach (thisPoint) ->
          scope.map.local.route.start = thisPoint
          scope.$apply()
          expect(point.status).toBe("inactive")
          expect(scope.map.currentMarker.status).toBe("inactive")

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
    