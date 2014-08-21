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
  controller = {}
  points = []
  timeout = {}

  beforeEach module('mapApp')

  beforeEach inject (_$httpBackend_, $rootScope, $timeout, sharedProperties, $controller) -> 
      $httpBackend = _$httpBackend_
      timeout = $timeout
      $httpBackend.expectGET('php/routes.php?method=getRoutes').respond(200, routeObjs)
      scope = $rootScope.$new()
      controller = $controller('mapController', {$scope: scope})
      $httpBackend.flush()
      scope.map.local.points.forEach (point) ->
        point.clickStart = () -> scope.map.local.start = @id
        point.clickEnd = () -> scope.map.local.end = @id
        point.model = point

      points = scope.map.local.points
        
  
  xit('should correctly place markers in correct models.', ->
    expect(scope.map.local.points.length).toBe(4)
    expect(scope.map.local.startPoints.length).toBe(3)
    expect(scope.map.local.endPoints.length).toBe(3)
  ) 

  xit('should set current marker focused when clicked.', ->
    scope.map.local.points.forEach (point) ->
      point.onClick()
      expect(point.status).toBe("focused")
      scope.map.local.points.forEach (point) -> expect(point.prevIcon).toMatch(new RegExp(point.status)) unless point.status is "focused"
  )

  xit('should set marker back to original when info window is closed.', ->
    scope.map.local.points.forEach (point) ->
      point.close()
      expect(point.prevIcon).toMatch(point.status)
  )

  describe 'the start and end points', ->

    it('should save each marker if it correctly corresponds to an entry or exit', ->
      scope.$apply()
      scope.test = 1
      scope.$apply()
      expect(scope.test).toBe(2)
    )
    
    