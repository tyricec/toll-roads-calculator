# Class for the markers
class Marker
  constructor: (@id, @name, @type, @latlng, @freeway, @point_type) ->
    @start = null
    @end = null
    @displayName = "SR " + @freeway + " -- " + @name
    @typeString = "SR #{@freeway}" 
    unless @type is "plaza"
      @markerType = "Access Point:" 
    else
      @markerType = "Toll Plaza:"    
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
