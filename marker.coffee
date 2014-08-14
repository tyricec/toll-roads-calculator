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
    unless @type is "plaza"
      @icon = "/states/inactive.png"
      @prevIcon = "/states/inactive.png"
    else
      @icon = "/states/plaza.png"
      @prevIcon = "/states/plaza.png"
    @showWindow = false
    @refresh = true
