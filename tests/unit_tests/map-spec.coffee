describe 'map-controller', ->
  routeObjs = [
    {"route_id": '1', "route_name": "test1", "route_lat": 0, "route_long": 0, "route_type": "point", "route_point_type": "entry/exit", "route_fwy": 241},
    {"route_id": '2', "route_name": "test2", "route_lat": 0, "route_long": 0, "route_type": "point", "route_point_type": "entry", "route_fwy": 241},
    {"route_id": '3', "route_name": "test3", "route_lat": 0, "route_long": 0, "route_type": "point", "route_point_type": "exit", "route_fwy": 241},
    {"route_id": '4', "route_name": "test4", "route_lat": 0, "route_long": 0, "route_type": "point", "route_point_type": "entry/exit", "route_fwy": 73},
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
      infoController = $controller('infoController', {$scope: scope})
      
      $httpBackend.flush()
      
      scope.map.local.points.forEach (point) ->
        point.clickStart = () -> scope.map.local.start = @id
        point.clickEnd = () -> scope.map.local.end = @id
        point.model = point

      points = scope.map.local.points

      spyOn(scope, "$broadcast").andCallThrough()
        
  
  it('should correctly place markers in correct models.', ->
    expect(scope.map.local.points.length).toBe(4)
    expect(scope.map.local.startPoints.length).toBe(3)
    expect(scope.map.local.endPoints.length).toBe(3)
  ) 

  it('should set current marker focused when clicked.', ->
    scope.map.local.points.forEach (point) ->
      point.onClick()
      expect(point.status).toBe("focused")
      # Check if the rest are default
      scope.map.local.points.forEach (point) -> expect(point.prevIcon).toMatch(new RegExp(point.status)) unless point.status is "focused"
  )

  it('should set marker back to original when info window is closed.', ->
    scope.map.local.points.forEach (point) ->
      point.close()
      expect(point.prevIcon).toMatch(point.status)
  )

  it('should show start/end buttons based on the type of point.', ->
    points.forEach (point) ->
      point.onClick()
      scope.$apply()
      expect(scope.$broadcast).toHaveBeenCalledWith('marker-clicked', point)
      if point.point_type isnt "exit"
        expect(scope.props.showStartBtn).toBe(true)
      if point.point_type isnt "entry"
        expect(scope.props.showEndBtn).toBe(true)
  )

  describe 'the start and end points', ->

    it('should save be saved in route object when the start or end button is clicked', ->
      points.forEach (point) ->
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
    
    