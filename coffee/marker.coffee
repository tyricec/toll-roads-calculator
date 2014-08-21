# Class for the markers
class Marker
  constructor: (@id, @name, @type, @latlng, @freeway, @point_type) ->
    @start = null
    @end = null
    @displayName = @freeway + " " + @name
    unless @type is "plaza"
      @typeString = "Access Point: CA #{@freeway}" 
    else
      @typeString = "Plaza: CA #{@freeway}"    
    @glatlng = { lat: @latlng.latitude, lng: @latlng.longitude }
    unless @type is "plaza"
      @status = "inactive"
      @icon = "states/inactive.png"
      @prevIcon = "states/inactive.png"
    else
      @status = "inactive"
      @icon = "states/plaza.png"
      @prevIcon = "states/plaza.png"
    @showWindow = false
    @refresh = true
