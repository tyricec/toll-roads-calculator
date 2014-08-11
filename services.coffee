app = angular.module 'services', []

# Services used by controllers
app.service 'sharedProperties', ->
  props = {
    route: { start: -1, end: -1 },
    markers: [],
    panorama: {}
  }
  
  return {
    Properties: -> return props,
    setStart: (val) -> return props.route.start = val,
    setEnd: (val) -> return props.route.end = val,
    setMarkers: (val) -> return props.markers = val,
    setPanorama: (val) -> return props.panorama = val.getGMap().getStreetView()
  }

app.service 'markerService', ->
  return {
    setMarkerStatus: (marker, status) ->
      if not marker?
        return
      else
        marker.status = status
        marker.showWindow = true if status is 'focused'
        marker.prevIcon = "/states/#{status}.png" if status isnt 'focused'
        marker.icon = "/states/#{status}.png"
    ,
    setMarkerDefault: (marker) ->
      marker.showWindow = false
      marker.icon = marker.prevIcon
  }