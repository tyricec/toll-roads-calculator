app = angular.module 'mapApp', ['google-maps', 'services', 'ui.bootstrap']

# InfoWindow controller
app.controller 'infoController', ['$scope', 'sharedProperties', ($scope, sharedProperties) ->
  $scope.onStartClick = () -> 
    props = sharedProperties.Properties()
    id = $scope.model.id
    sharedProperties.setEnd 0 if props.route.end is id
    sharedProperties.setStart($scope.model) 
  
  $scope.onEndClick = () -> 
    props = sharedProperties.Properties()
    id = $scope.model.id
    sharedProperties.setStart 0 if props.route.start is id
    sharedProperties.setEnd($scope.model) 

  $scope.onStreetViewClick = ->
    properties = sharedProperties.Properties()
    currentMarker = $scope.model
    properties.panorama.setPosition currentMarker.glatlng
    $scope.$emit('street-view-clicked')
]

# Map Controller

app.controller 'mapController', ['$scope', '$http', '$compile', 'sharedProperties', 'markerService', 
 ($scope, $http, $compile, sharedProperties, markerService) ->

  $http.get('php/routes.php?method=getRoutes').success( (points) -> 
    # Creating the markers
    allPoints = []
    startPoints =  []
    endPoints = []
    markerPlazas = []
    points.forEach (element) ->
      do -> 
        latlng = {'latitude': parseFloat(element.route_lat), 'longitude': parseFloat(element.route_long)}
        marker = new Marker(parseInt(element.route_id), element.route_name, 
          element.route_type, latlng, element.route_fwy, element.route_point_type
        )
        marker.close = ->
          markerService.setMarkerDefault @model
          $scope.$apply()
	  
        marker.onClick = ->
          # Set all markers to their default just in case one that was focused wasn't closed
          setMarkersDefault = (cb) -> 
            $scope.map.local.points.forEach((element) -> do -> markerService.setMarkerDefault element)
            $scope.map.local.plazas.forEach((element) -> do -> markerService.setMarkerDefault element)
            return cb()
          setMarkersDefault =>
            markerService.setMarkerStatus @model, "focused"
            $scope.id = @model.id
            $scope.typeString = @model.typeString
            $scope.markerTitle = @model.name
            $scope.$apply()
        if marker.type is "point"
          allPoints.push(marker)
        if marker.type is "point" and marker.point_type isnt "exit"
          startPoints.push(marker)
        if marker.type is "point" and marker.point_type isnt "entry"
          endPoints.push(marker)
        if marker.type is "plaza"
          markerPlazas.push(marker)
    return do ->
      $scope.map.local.points = allPoints
      $scope.map.local.startPoints = startPoints
      $scope.map.local.endPoints = endPoints
      $scope.map.local.plazas = markerPlazas
      $scope.map.local.displayPoints = endPoints
  )
  
  $scope.map = {
    'center': {'latitude': 33.689388, 'longitude': -117.731235},
    'zoom': 11,
    'streetView': {},
    'innerElementsLoaded': false,
    'local': sharedProperties.Properties(),
    'showTraffic': false,
    'showStreetView': true,
    'closeStreetView': ( -> 
      panoEl = angular.element('#pano')
      panoEl.animate({"height": 0}, {"complete": -> $scope.map.showStreetView = false})
      return true    # Only needed because coffeescript returns dom elements which scares angular
    ),
    'toggleTrafficLayer': -> $scope.map.showTraffic = !$scope.map.showTraffic,
    'mapOptions': {
      'panControl': false,
      'rotateControl': false,
      'streetViewControl': false,
      'zoomControlOptions': {
        'position': google.maps.ControlPosition.BOTTOM_LEFT
      }
    }
    'infoWindowOptions': {
      'pixelOffset': new google.maps.Size(0, -30)
    },
    'events': {
      # Invoked when the map is loaded
      'idle': (map) ->
        unless $scope.map.innerElementsLoaded
          angular.element('.infoWindow').show()
          # Add traffic layer btn to map
          addTrafficBtn = () ->
            element = document.createElement 'div'
            el = angular.element element
            el.append '<button ng-click="map.toggleTrafficLayer()">Traffic</button>'
          
            # Need to invoke compile for click event to be registered to button
            $compile(el)($scope)
            map.controls[google.maps.ControlPosition.TOP_RIGHT].push el[0]

          addCloseStreetBtn = (callback) ->
            element = document.createElement 'div'
            el = angular.element element
            el.append '<button id="closeStreetView" ng-click="map.closeStreetView()">Close</button>'
            $compile(el)($scope)
            panorama = sharedProperties.Properties().panorama
            panorama.controls[google.maps.ControlPosition.TOP_RIGHT].push el[0]
            return callback()

          loadStreetView = (cb) ->
            sharedProperties.setPanorama map
            return cb()

          loadStreetView -> addCloseStreetBtn -> $scope.map.innerElementsLoaded = true

          addTrafficBtn()
    }

  }
  
  preparePeakRates = (peakrates) ->
    peakrates.forEach( (rate, index) ->
      rate.descriptionId = Array(index + 2).join "*"
    )

  
  # Form submit function
  $scope.getRate = ->
    startId = $scope.map.local.route.start.id
    endId = $scope.map.local.route.end.id
    type = $scope.map.local.route.type
    axles = $scope.map.local.route.axles
    $http.get("php/rates.php?method=getRate&entry=#{startId}&exit=#{endId}&type=#{type}&axles=#{axles}").success( (resp) ->
      rateObj = $scope.map.local.route.rateObj = resp
      if rateObj.rates?
        preparePeakRates(rateObj.rates.peak) if rateObj.rates.peak?
				
    )

  $scope.$on("street-view-clicked", ->
    panoEl = angular.element("#pano")
    # Initial state of map. Needed to bring map up.
    if $scope.map.showStreetView is true and panoEl.css('z-index') is "-1"
      panoEl.css({"z-index": 1, "height": 0})
      panoEl.hide()
      $scope.map.showStreetView = false
    # Show map
    if $scope.map.showStreetView is false
      $scope.map.showStreetView = true
      panoEl.show()
      panoEl.animate({"height": "45%"})
  )

  $scope.test = 0

  $scope.$watch('test', (newValue) ->
    newValue = newValue + 1
  )

  # Used to change the options displayed for dropdown on certain condition.
  reduceDropdownOptions = (cond) ->
    points = $scope.map.local.endPoints
    newPoints = []
    newPoints.push point for point in points when cond(point)
    $scope.map.local.displayPoints = newPoints
  
  $scope.$watchCollection 'map.local.route', (newValues, oldValues, scope) ->
    # Need to check to see which point has changed. Useful in updating what can be selected later.
    $scope.test = $scope.test + 1 unless not $scope.test?
    $scope.test = 1 unless $scope.test
    if newValues.start is null
      newValues.start = 0
      $scope.map.local.points.forEach((marker) ->
        return markerService.setMarkerStatus(marker, "inactive") unless marker.status is "end"
      )
    if newValues.end is null
      newValues.end = 0
      $scope.map.local.points.forEach( (marker) ->
        return markerService.setMarkerStatus(marker, "inactive") unless marker.status is "start"
      )
    if newValues.start.freeway is "73" and newValues.end.freeway isnt "73"
      newValues.end = 0
    else if newValues.start.freeway isnt "73" and newValues.end.freeway is "73"
      newValues.end = 0
    startPointChanged = (oldValues.start.id isnt newValues.start.id) or not oldValues.start.id? or not newValues.start.id?
    startPoint = newValues.start
    endPoint = newValues.end
    # Check is needed just in case the current start is trying to be overwritten by end
    if (startPoint is 0) and (endPoint is 0) or (startPoint.id is endPoint.id)
      points = $scope.map.local.points
      $scope.map.local.displayPoints = points if (startPoint is 0) and (endPoint is 0)
      return sharedProperties.setStart 0 if oldValues.start.id is startPoint.id
      return sharedProperties.setEnd 0 if oldValues.end.id is endPoint.id
    points = sharedProperties.Properties().points
    # Set other markers that were previously start or end to inactive
    points.forEach (marker) ->
      if marker.status is "start" or marker.status is "end"
        markerService.setMarkerStatus marker, "inactive" 
    
    reduceDropdownOptions( (marker) ->
      return true if startPoint is ""
      if startPoint.freeway is "73"
        return marker.freeway is "73" 
      else
        return marker.freeway isnt "73"
    )
    sharedProperties.setPoints points
    markerService.setMarkerStatus startPoint, "start"
    markerService.setMarkerStatus endPoint, "end"
]
