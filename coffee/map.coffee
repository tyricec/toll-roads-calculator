app = angular.module 'mapApp', ['google-maps', 'services', 'ui.bootstrap']

# Map Controller

app.controller 'mapController', ['$scope', '$http', '$compile', 'sharedProperties', 'markerService', 
 ($scope, $http, $compile, sharedProperties, markerService) ->

  $http.get('php/routes.php?method=getRoutes').success( (points) -> 
    # Creating the markers
    allPoints = []
    startPoints =  []
    endPoints = []
    markerPlazas = []
    points73 = []
    pointsRest = []
    startPoints73 = []
    endPoints73 = []
    startPointRest = []
    endPointsRest = []
    points.forEach (element) ->
      do -> 
        latlng = {'latitude': parseFloat(element.route_lat), 'longitude': parseFloat(element.route_long)}
        marker = new Marker(parseInt(element.route_id), element.route_name, 
          element.route_type, latlng, element.route_fwy, element.route_point_type
        )

        marker.onClick = ->
          $scope.showStartBtn = @model.showStartBtn
          $scope.showEndBtn = @model.showEndBtn
          $scope.map.currentMarker = @model
          if $scope.map.currentMarker.type isnt 'plaza'
            $scope.map.showWindow = true
          else
            $scope.map.showWindow = false
          # Set all markers to their default just in case one that was focused wasn't closed
          setMarkersDefault = (cb) -> 
            $scope.map.local.points.forEach((element) -> do -> markerService.setMarkerDefault element)
            $scope.map.local.plazas.forEach((element) -> do -> markerService.setMarkerDefault element)
            return cb()
          setMarkersDefault =>
            markerService.setMarkerStatus @model, "focused"
            $scope.map.local.currentMarker = @model
            $scope.id = @model.id
            $scope.typeString = @model.typeString
            #$scope.markerTitle = @model.name
            $scope.markerType = @model.markerType
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
        if marker.freeway is '73' and marker.type is "point"
          points73.push(marker)
        else if marker.type is "point"
          pointsRest.push(marker)
    return do ->
      $scope.map.local.startPoints = startPoints
      $scope.map.local.endPoints = endPoints
      $scope.map.local.plazas = markerPlazas
      $scope.map.local.startDisplayOpts = []
      $scope.map.local.endDisplayOpts = []
      $scope.map.local.points73 = points73
      $scope.map.local.pointsRest = pointsRest
      $scope.map.local.startPoints73 = startPoints.filter (point) -> point.freeway is "73"
      $scope.map.local.endPoints73 = endPoints.filter (point) -> point.freeway is "73"
      $scope.map.local.startPointsRest = startPoints.filter (point) -> point.freeway isnt "73"
      $scope.map.local.endPointsRest = endPoints.filter (point) -> point.freeway isnt "73"
      $scope.map.local.route.fwy = "rest"
  )
  
  $scope.map = {
    'center': {'latitude': 33.689388, 'longitude': -117.731235},
    'zoom': 11,
    'streetView': {},
    'fitMarkers': false,
    'pan': false,
    'control': {},
    'innerElementsLoaded': false,
    'local': sharedProperties.Properties(),
    'showTraffic': false,
    'showStartBtn': true,
    'showStreetView': true,
    'currentMarker': {},
    'showWindow' : false,
    'closeWindow': ( ->
       $scope.map.local.closeWindow($scope)
    ),
    'switchPoints': ( ->
      tempStartPoint = $scope.map.local.route.start
      tempEndPoint = $scope.map.local.route.end
      $scope.map.local.route.start = tempEndPoint
      $scope.map.local.route.end = tempStartPoint
    ),
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
      'mapTypeControl': false,
      'zoomControlOptions': {
        'position': google.maps.ControlPosition.BOTTOM_LEFT
      }
    }
    'infoWindowOptions': {
      'pixelOffset': new google.maps.Size(0, -30)
    },
    'markerOptions' :{
      'visible': true
    }
    'events': {
      # Invoked when the map is loaded
      'idle': (map) ->
        #$scope.map.local.mapObj = map
        unless $scope.map.innerElementsLoaded
          # Add initial points, startDisplayOpts, and endDisplayOpts
          $scope.map.local.points = $scope.map.local.pointsRest
          $scope.map.local.startDisplayOpts = $scope.map.local.startPointsRest
          $scope.map.local.endDisplayOpts = $scope.map.local.endPointsRest
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
    rateEl = angular.element("#calc-results")
    rateEl.slideUp(200, -> 
      startId = $scope.map.local.route.start.id
      endId = $scope.map.local.route.end.id
      type = $scope.map.local.route.type
      axles = $scope.map.local.route.axles
      $http.get("php/rates.php?method=getRates&start=#{startId}&end=#{endId}&type=#{type}&axles=#{axles}").success( (resp) ->
        rateObj = $scope.map.local.route.rateObj = resp
        if rateObj.rates?
          preparePeakRates(rateObj.rates.peak) if rateObj.rates.peak?	
        rateEl.slideDown()		
      )
    )

  handleStreetView = ->
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

  # Used to change the options displayed for dropdown on certain condition.
  reduceDropdownOptions = (cond) ->
    points = $scope.map.local.endPoints
    newPoints = []
    newPoints.push point for point in points when cond(point)
    $scope.map.local.endDisplayOpts = newPoints
  
  $scope.$watch 'map.local.route.fwy' , (newValue,oldValue,scope) ->
    $scope.map.local.route.start = 0
    $scope.map.local.route.end = 0

    if newValue is '73'
      $scope.map.local.points = $scope.map.local.points73
      $scope.map.local.startDisplayOpts = $scope.map.local.startPoints73
      $scope.map.local.endDisplayOpts = $scope.map.local.endPoints73
    else
      $scope.map.local.points = $scope.map.local.pointsRest
      $scope.map.local.startDisplayOpts = $scope.map.local.startPointsRest
      $scope.map.local.endDisplayOpts = $scope.map.local.endPointsRest
      
    $scope.map.local.fitBounds()

  $scope.$watchCollection 'map.local.route', (newValues, oldValues, scope) ->
    points = sharedProperties.Properties().points
    startPoints = $scope.map.local.startPoints
    endPoints = $scope.map.local.endPoints
    #populate dd list depending in fwy
    if newValues.fwy == "73" or newValues.fwy == "73"
      startPointsOpts = $scope.map.local.startPoints73
      endPointsOpts = $scope.map.local.endPoints73
    else
      startPointsOpts = $scope.map.local.startPointsRest
      endPointsOpts = $scope.map.local.endPointsRest
    return false if not startPoints? or not endPoints?
    # Set other markers that were previously start or end to inactive
    points.forEach (marker) ->
      if marker.status is "start" or marker.status is "end"
        markerService.setMarkerStatus marker, "inactive"
    
    $scope.map.local.startDisplayOpts = startPointsOpts.filter (point) -> point isnt newValues.end
    $scope.map.local.endDisplayOpts = endPointsOpts.filter (point) -> point isnt newValues.start

    sharedProperties.setPoints points
    markerService.setMarkerStatus newValues.start, "start"
    markerService.setMarkerStatus newValues.end, "end"

    markerService.setMarkerDefault $scope.map.local.currentMarker if $scope.map.local.currentMarker?
    $scope.map.local.closeWindow($scope)
    $scope.map.local.fitBounds()

  $scope.onStartClick = () -> 
    marker = $scope.map.local.currentMarker    
    id = marker.id
    sharedProperties.setEnd 0 if $scope.map.local.route.end.id is id
    sharedProperties.setStart(marker)
    $scope.map.local.fitBounds()
    $scope.map.local.closeWindow($scope)
  
  $scope.onEndClick = () -> 
    marker = $scope.map.local.currentMarker
    id = marker.id
    sharedProperties.setStart 0 if $scope.map.local.route.start.id is id
    sharedProperties.setEnd(marker) 
    $scope.map.local.fitBounds()
    $scope.map.local.closeWindow($scope)
   
  $scope.onStreetViewClick = ->
    currentMarker = $scope.map.local.currentMarker  
    $scope.map.local.panorama.setPosition currentMarker.glatlng
    handleStreetView()
]
