# Class for the markers
class Marker
  constructor: (@id, @latlng) ->
    @start = null
    @end = null
    @glatlng = { lat: @latlng.latitude, lng: @latlng.longitude }
    @icon = "/states/inactive.png"
    @prevIcon = "/states/inactive.png"
    @showWindow = false
