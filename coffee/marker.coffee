# Class for the markers
class Marker
  constructor: (@id, @name, @type, @latlng, @freeway, @point_type) ->
    @start = null
    @end = null
    if @freeway is "73" 
      @displayName = @name
    else
      @displayName = @freeway + " -- " + @name
    @typeString = "SR #{@freeway}" 
    unless @type is "plaza"
      @markerType = "Access Point:" 
    else
      @markerType = "Toll Plaza:"    
    @glatlng = { lat: @latlng.latitude, lng: @latlng.longitude }
    @maplatlng = new google.maps.LatLng(@glatlng.lat, @glatlng.lng)
    @markerOptions = {
      'optimized': false,
      'title': "#{@id}"
    }
    unless @type is "plaza"
      @status = "inactive"
      @icon = "states/inactive.png"
      @prevIcon = "states/inactive.png"
    else
      @status = "inactive"
      @icon = "states/plaza.png"
      @prevIcon = "states/plaza.png"
    @showWindow = false
    if @point_type isnt "exit" then @showStartBtn = true else @showStartBtn = false
    if @point_type isnt "entry" then @showEndBtn = true else @showEndBtn = false
