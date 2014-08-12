app = angular.module 'mapApp', ['google-maps', 'services']

# InfoWindow controller
app.controller 'infoController', ['$scope', 'sharedProperties', ($scope, sharedProperties) ->
  
  $scope.onStartClick = () -> 
    props = sharedProperties.Properties()
    id = $scope.model.id
    sharedProperties.setEnd 0 if props.route.end is id
    sharedProperties.setStart($scope.model.id) 
  $scope.onEndClick = () -> 
    props = sharedProperties.Properties()
    id = $scope.model.id
    sharedProperties.setStart 0 if props.route.start is id
    sharedProperties.setEnd($scope.model.id) 

  $scope.onStreetViewClick = ->
    properties = sharedProperties.Properties()
    currentMarker = properties.markers[$scope.model.id]
    properties.panorama.setPosition currentMarker.glatlng
    $scope.$emit('street-view-clicked')
]

# Map Controller

app.controller 'mapController', ['$scope', '$http', '$compile', 'sharedProperties', 'markerService', 
 ($scope, $http, $compile, sharedProperties, markerService) ->

  initMarkers = -> 
    $http.get('/php/routes.php?method=getRoutes').success( (points) -> 
      # Creating the markers
      markers = []
      points.forEach (element) ->
        do -> 
          latlng = {'latitude': parseFloat(element.route_lat), 'longitude': parseFloat(element.route_long)}
          marker = new Marker(parseInt(element.route_id), element.route_name, 
            element.route_type, latlng, element.route_fwy
          )
          marker.close = ->
            markerService.setMarkerDefault @model
            $scope.$apply()
	  
          marker.onClick = ->
            # Set all markers to their default just in case one that was focused wasn't closed
            setMarkersDefault = (cb) -> 
              $scope.map.local.markers.forEach((element) -> do -> markerService.setMarkerDefault element)
              return cb()
            setMarkersDefault => 
              markerService.setMarkerStatus @model, "focused"
              $scope.id = @model.id
              $scope.$apply()

          markers.push marker
      return do -> $scope.map.local.markers = markers
    )

  initMarkers()
  
  $scope.map = {
    'center': {'latitude': 33.884388, 'longitude': -117.641235},
    'zoom': 12,
    'streetView': {},
    'local': sharedProperties.Properties(),
    'showTraffic': false,
    'showStreetView': true,
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
          el.append '<button id="closeStreetView" ng-click="map.handleStreetView()">Close</button>'
          $compile(el)($scope)
          panorama = sharedProperties.Properties().panorama
          panorama.controls[google.maps.ControlPosition.TOP_RIGHT].push el[0]
          return callback()

        loadStreetView = (cb) ->
          sharedProperties.setPanorama map
          return cb()

        loadStreetView -> addCloseStreetBtn -> angular.element("#pano").slideToggle(800)

        addTrafficBtn()
    }

  }
  
  $scope.$on("street-view-clicked", ->
    panoEl = angular.element("#pano")
    if $scope.map.showStreetView is true
      panoEl.css("height", 0) unless panoEl.css("z-index") is -1
  )

  $scope.$watchCollection 'map.local.route', (newValues, oldValues, scope) ->
    startId = newValues.start
    endId = newValues.end
    # Check is needed just in case the current start is trying to be overwritten by end
    if (startId is 0) and (endId is 0) or (startId is endId)
      return sharedProperties.setStart 0 if oldValues.start is startId
      return sharedProperties.setEnd 0 if oldValues.end is endId
    markers = sharedProperties.Properties().markers
    # Set other markers that were previously start or end to inactive
    markers.forEach (marker) ->
      if marker.status is "start" or marker.status is "end"
        markerService.setMarkerStatus marker, "inactive" 
    
    sharedProperties.setMarkers markers
    markerService.setMarkerStatus markers[startId - 1], 'start'; markerService.setMarkerStatus markers[endId - 1], 'end'
]
