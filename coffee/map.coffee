app = angular.module 'mapApp', ['google-maps', 'services', 'ui.bootstrap', 'Alert']

# Map Controller

app.controller 'mapController', ['$scope', '$http', '$compile', 'sharedProperties', 'markerService', 
 ($scope, $http, $compile, sharedProperties, markerService) ->

  $http.get('php/routes.php?method=getRoutes').success( (points) -> 
    # Creating the markers
    allPoints = []
    startPoints =  []
    endPoints = []
    markerPlazas = []
    markerPlazas73 = []
    markerPlazasRest = []
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
          if $scope.map.local.route.start? and (@model.id is $scope.map.local.route.start.id)
            angular.element(".start-btn").attr('disabled', true) 
          else 
            angular.element(".start-btn").attr('disabled', false)
          if $scope.map.local.route.end? and (@model.id is $scope.map.local.route.end.id )
            angular.element(".end-btn").attr('disabled', true) 
          else
            angular.element(".end-btn").attr('disabled', false)
          if @model.type is "point" 
            $scope.map.showWindow = true
            $scope.map.showPlazaWindow = false
          else 
            $scope.map.showWindow = false
            $scope.map.showPlazaWindow = true
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
        if marker.freeway is '73'
          if marker.type is "point"
            points73.push(marker)
          else 
            markerPlazas73.push(marker)
        else if marker.type is "point"
          pointsRest.push(marker)
        else
          markerPlazasRest.push(marker)
    return do ->
      $scope.map.local.startPoints = startPoints
      $scope.map.local.endPoints = endPoints
      $scope.map.local.startDisplayOpts = []
      $scope.map.local.endDisplayOpts = []
      $scope.map.local.points73 = points73
      $scope.map.local.pointsRest = pointsRest
      $scope.map.local.plazas73 = markerPlazas73
      $scope.map.local.plazasRest = markerPlazasRest
      $scope.map.local.startPoints73 = startPoints.filter (point) -> point.freeway is "73"
      $scope.map.local.endPoints73 = endPoints.filter (point) -> point.freeway is "73"
      $scope.map.local.startPointsRest = startPoints.filter (point) -> point.freeway isnt "73"
      $scope.map.local.endPointsRest = endPoints.filter (point) -> point.freeway isnt "73"
      $scope.map.local.route.fwy = "rest"
  )

  switchablePoint = (point) ->
    return true if (point? and point.point_type is "entry/exit") or not point?
    return false
  
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
    'startDisabled': false,
    'endDisabled': false,
    'currentMarker': {},
    'showWindow' : false,
    'showPlazaWindow': false,
    'showFwyRest': true,
    'showFwy73': false,
    'closeWindow': ( ->
       $scope.map.local.closeWindow($scope)
    ),
    'switchPoints': ( ->
      tempStartPoint = $scope.map.local.route.start
      tempEndPoint = $scope.map.local.route.end
      if not (switchablePoint tempStartPoint) or not (switchablePoint tempEndPoint)
        console.log switchablePoint tempEndPoint
        console.log switchablePoint tempStartPoint
        return showAlert 'Reverse Trip cannot be completed. One of your selections is a one-way access point and cannot be swtiched.'
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
      'scrollwheel': false,
      'mapTypeControl': false,
      'maxZoom': 16,
      'minZoom': 11,
      'zoomControlOptions': {
        'position': google.maps.ControlPosition.BOTTOM_LEFT
      }
    }
    'infoWindowOptions': {
      'pixelOffset': new google.maps.Size(0, -30)
    },
    'restLayerOptions': {
      'url': 'http://ditisfl.org/toll-roads-calculator/kml/TCA_Toll_Roads_090514_Projec-133_241_261.kml'
    },
    'layer73Options': {
      'url': 'http://ditisfl.org/toll-roads-calculator/kml/TCA_Toll_Roads_090514_Projec-73.kml'
    },
    'events': {
      # Invoked when the map is loaded
      'idle': (map) ->
        unless $scope.map.innerElementsLoaded
          # Add traffic layer btn to map
          addTrafficBtn = () ->
            element = document.createElement 'div'
            el = angular.element element
            el.append '<button class="btn btn-default btn-custom btn-blue" ng-click="map.toggleTrafficLayer()">Live Traffic</button>'
          
            # Need to invoke compile for click event to be registered to button
            $compile(el)($scope)
            map.controls[google.maps.ControlPosition.TOP_RIGHT].push el[0]

          addCloseStreetBtn = (callback) ->
            element = document.createElement 'div'
            el = angular.element element
            el.append '<button id="closeStreetView" class="btn btn-default btn-custom btn-blue" ng-click="map.closeStreetView()">Close Street View</button>'
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

  showAlert = (message) ->
    $("#map-alert").html(message)
    $scope.map.local.showMapAlert = true
    return false
  
  preparePeakRates = (peakrates) ->
    peakrates.forEach( (rate, index) ->
      rate.descriptionId = Array(index + 2).join "*"
    )

  
  formValidated = ->
    return false if not $scope.map.local.route.start?
    return false if not $scope.map.local.route.end?
    return false if not $scope.map.local.route.type?
    return false if not $scope.map.local.route.axles?
    return true
  
  # Form submit function
  $scope.getRate = ->
    return showAlert 'Calculate Your Toll cannot be completed.  Start and end points must be selected to get a toll rate.' if not formValidated()
    rateEl = angular.element("#calculator-results")
    rateEl.slideUp(200, -> 
      startId = $scope.map.local.route.start.id
      endId = $scope.map.local.route.end.id
      type = $scope.map.local.route.type
      axles = $scope.map.local.route.axles
      $http.get("php/rates.php?method=getRates&start=#{startId}&end=#{endId}&type=#{type}&axles=#{axles}").success( (resp) ->
        $scope.map.local.route.offPeakText = if resp.payment is "One-Time-Toll" then "One-Time-Toll" else "Off Peak"
        panoEl = angular.element("#calculator-results div")
        if resp.rates.off_peak is "No Toll"
          panoEl.hide()
          $scope.map.local.route.resultText = "No toll required for this trip"
        else 
          rateObj = $scope.map.local.route.rateObj = resp
          $scope.map.local.route.resultText = "Your toll for this one-way trip:"
          panoEl.show()
          if rateObj.rates?
            preparePeakRates(rateObj.rates.peak) if rateObj.rates.peak?	
        rateEl.slideDown()
      )
    )
    return true

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
      panoEl.animate({"height": "55%"})
    return true

  # Used to change the options displayed for dropdown on certain condition.
  reduceDropdownOptions = (cond) ->
    points = $scope.map.local.endPoints
    newPoints = []
    newPoints.push point for point in points when cond(point)
    $scope.map.local.endDisplayOpts = newPoints
  

  isUnknown = (value) ->
    return false if not value?
    unknownRegX = new RegExp(/unknown/i)
    return true if unknownRegX.test value.name
    return false

  reduceToOneTime = ->
    $scope.map.local.displayTypes.forEach (type, index) ->
      $scope.map.local.route.type = "onetime"
      if type.id isnt "onetime"
        $scope.map.local.displayTypes = []
        $scope.map.local.displayTypes = $scope.map.local.onetimetype

  setAllTypes = ->
    $scope.map.local.displayTypes = []
    $scope.map.local.types.forEach (type) ->
       $scope.map.local.displayTypes.push type

  $scope.$watch 'map.local.route.fwy' , (newValue,oldValue,scope) ->
    $scope.map.local.route.start = null
    $scope.map.local.route.end = null

    if newValue is '73'
      $scope.map.local.points = $scope.map.local.points73
      $scope.map.local.plazas = $scope.map.local.plazas73
      $scope.map.local.startDisplayOpts = $scope.map.local.startPoints73
      $scope.map.local.endDisplayOpts = $scope.map.local.endPoints73
      $scope.map.showFwy73 = true
      $scope.map.showFwyRest = false
    else
      $scope.map.local.points = $scope.map.local.pointsRest
      $scope.map.local.plazas = $scope.map.local.plazasRest
      $scope.map.local.startDisplayOpts = $scope.map.local.startPointsRest
      $scope.map.local.endDisplayOpts = $scope.map.local.endPointsRest
      $scope.map.showFwy73 = false
      $scope.map.showFwyRest = true
      
    $scope.map.local.fitBounds()

  $scope.$watchCollection 'map.local.route', (newValues, oldValues, scope) ->
    points = sharedProperties.Properties().points
    startPoints = $scope.map.local.startPoints
    endPoints = $scope.map.local.endPoints

    # Check if start and end are unknown. Switch pay by value to only have one time
    if isUnknown(newValues.start) or isUnknown(newValues.end) then reduceToOneTime() else setAllTypes()

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
    if $scope.map.local.route.end?
      sharedProperties.setEnd null if $scope.map.local.route.end.id is id
    sharedProperties.setStart(marker)
    $scope.map.local.fitBounds()
    $scope.map.local.closeWindow($scope)
  
  $scope.onEndClick = () -> 
    marker = $scope.map.local.currentMarker
    id = marker.id
    if $scope.map.local.route.start?
      sharedProperties.setStart null if $scope.map.local.route.start.id is id
    sharedProperties.setEnd(marker) 
    $scope.map.local.fitBounds()
    $scope.map.local.closeWindow($scope)
   
  $scope.onStreetViewClick = ->
    currentMarker = $scope.map.local.currentMarker  
    $scope.map.local.panorama.setPosition currentMarker.glatlng
    handleStreetView()
]
