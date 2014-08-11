app = angular.module 'mapApp', ['google-maps', 'services']

# InfoWindow controller
app.controller 'infoController', ['$scope', 'sharedProperties', ($scope, sharedProperties) ->
  
  $scope.onStartClick = () -> 
    props = sharedProperties.Properties()
    id = $scope.model.id
    sharedProperties.setEnd -1 if props.route.end is id
    sharedProperties.setStart($scope.model.id) 
  $scope.onEndClick = () -> 
    props = sharedProperties.Properties()
    id = $scope.model.id
    sharedProperties.setStart -1 if props.route.start is id
    sharedProperties.setEnd($scope.model.id) 

  $scope.onStreetViewClick = ->
    properties = sharedProperties.Properties()
    currentMarker = properties.markers[$scope.model.id]
    panoramaOptions = {
        position : currentMarker.glatlng
      }
    panorama = new google.maps.StreetViewPanorama(document.getElementById('pano'),panoramaOptions)
    panorama.setVisible(true)
    $('#pano').animate({'height': 0}, 100).animate({'z-index': 1}, 1).animate({'height': 500}, 800)
    return true
]

# Map Controller

app.controller 'mapController', ['$scope', 'sharedProperties', 'markerService', 
 ($scope, sharedProperties, markerService) ->
  
  $scope.markers = []
  
  $scope.map = {
    'center': {'latitude': 33.884388, 'longitude': -117.641235},
    'zoom': 12,
    'streetView': {},
    'local': sharedProperties.Properties(),
    'showTraffic': false,
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
    }

  }
    
  latlngs = []

  latlngs.push {'latitude': 33.843801, 'longitude': -117.717234}
  latlngs.push {'latitude': 33.826690, 'longitude': -117.716419}
  latlngs.push {'latitude': 33.820415, 'longitude': -117.716977}
  
  # Creating the markers
  latlngs.forEach (element, index) ->
    marker = new Marker index, element
    marker.close = ->
      markerService.setMarkerDefault @model
      $scope.$apply()
	  
    marker.onClick = ->
      # Saving the streetview map
      sharedProperties.setPanorama $scope.map.streetView
      # Set all markers to their default just in case one that was focused wasn't closed
      $scope.map.local.markers.forEach (element) -> markerService.setMarkerDefault element
      markerService.setMarkerStatus @model, "focused"
      $scope.id = @model.id
      $scope.$apply()
	  
    $scope.map.local.markers.push marker
  
  $scope.$watchCollection 'map.local.route', (newValues, oldValues, scope) ->
    startId = newValues.start
    endId = newValues.end
    # Check is needed just in case the current start is trying to be overwritten by end
    if (startId is -1) and (endId is -1) or (startId is endId)
      return sharedProperties.setStart -1 if oldValues.start is startId
      return sharedProperties.setEnd -1 if oldValues.end is endId
    markers = sharedProperties.Properties().markers
    # Set other markers that were previously start or end to inactive
    markers.forEach (marker) ->
      if marker.status is "start" or marker.status is "end"
        markerService.setMarkerStatus marker, "inactive" 
    
    sharedProperties.setMarkers markers
    markerService.setMarkerStatus markers[startId], 'start'; markerService.setMarkerStatus markers[endId], 'end'
]
