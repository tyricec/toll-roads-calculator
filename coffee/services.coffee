app = angular.module 'services', []

# Services used by controllers
app.service 'sharedProperties', [ 'markerService', (markerService) ->
  props = {
    route: { fwy: '', start: 0, end: 0, type: 'fastrak', axles: 2 },
    mapControl: {},
    mapObj: {},
    points: [],
    plazas: [],
    panorama: {},
    displayPoints: [],                # The points allowed for user to select.
    fitBounds: ->
      return console.log false if not @points?
      bounds = new google.maps.LatLngBounds()
      @points.forEach (point) -> 
        if not isNaN(point.latlng.latitude) and not isNaN(point.latlng.longitude)
          bounds.extend(point.maplatlng) 
      @mapControl.getGMap().fitBounds bounds if @mapControl.getGMap?
    ,
    closeWindow: (  (scope) ->
       markerService.setMarkerDefault scope.map.currentMarker
       scope.map.showWindow = false
    )
  }
  
  return {
    Properties: -> return props,
    setStart: (val) -> return props.route.start = val,
    setEnd: (val) -> return props.route.end = val,
    setPoints: (val) -> return props.points = val,
    setPlazas: (val) -> return props.plazas= val,
    setPanorama: () -> 
     # currentMarker = props.points[0]
      panoEl = document.getElementById('pano')
      props.panorama = new google.maps.StreetViewPanorama(panoEl)
  }

]

app.service 'markerService', ->
  return {
    setMarkerStatus: (marker, status) ->
      if not marker?
        return
      else
        marker.status = status
        marker.showWindow = true if status is 'focused'
        unless marker.type is "plaza"
          marker.prevIcon = "states/#{status}.png" if status isnt 'focused'
          marker.icon = "states/#{status}.png"
    ,
    setMarkerDefault: (marker) ->
      marker.icon = marker.prevIcon
    ,
    applyToMarkers: (serviceFunction, markers, fargs...) ->
      markers.forEach( (marker) -> serviceFunction(marker, fargs) )
  }