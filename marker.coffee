# Class for the markers
class Marker
  constructor: (@id, @name, @type, @latlng, @freeway) ->
    @start = null
    @end = null
    unless @type is "plaza"
      @typeString = "Access Point: CA #{@freeway}" 
    else
      @typeString = "Plaza: CA #{@freeway}"    
    @glatlng = { lat: @latlng.latitude, lng: @latlng.longitude }
    @icon = "/states/inactive.png"
    @prevIcon = "/states/inactive.png"
    @showWindow = false
    @refresh = true
