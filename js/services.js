var app,
  __slice = [].slice;

app = angular.module('services', []);

app.service('sharedProperties', [
  'markerService', function(markerService) {
    var props;
    props = {
      route: {
        fwy: '',
        start: 0,
        end: 0,
        type: 'onetime',
        axles: 2
      },
      mapControl: {},
      mapObj: {},
      points: [],
      plazas: [],
      panorama: {},
      showMapAlert: false,
      displayPoints: [],
      fitBounds: function() {
        var bounds;
        if (this.points == null) {
          return false;
        }
        bounds = new google.maps.LatLngBounds();
        this.points.forEach(function(point) {
          if (!isNaN(point.latlng.latitude) && !isNaN(point.latlng.longitude)) {
            return bounds.extend(point.maplatlng);
          }
        });
        if (this.mapControl.getGMap != null) {
          return this.mapControl.getGMap().fitBounds(bounds);
        }
      },
      closeWindow: (function(scope) {
        markerService.setMarkerDefault(scope.map.currentMarker);
        return scope.map.showWindow = false;
      })
    };
    return {
      Properties: function() {
        return props;
      },
      setStart: function(val) {
        return props.route.start = val;
      },
      setEnd: function(val) {
        return props.route.end = val;
      },
      setPoints: function(val) {
        return props.points = val;
      },
      setPlazas: function(val) {
        return props.plazas = val;
      },
      setPanorama: function() {
        var panoEl;
        panoEl = document.getElementById('pano');
        return props.panorama = new google.maps.StreetViewPanorama(panoEl);
      }
    };
  }
]);

app.service('markerService', function() {
  return {
    setMarkerStatus: function(marker, status) {
      if (marker == null) {

      } else {
        marker.status = status;
        if (status === 'focused') {
          marker.showWindow = true;
        }
        if (marker.type !== "plaza") {
          if (status !== 'focused') {
            marker.prevIcon = "states/" + status + ".png";
          }
          return marker.icon = "states/" + status + ".png";
        }
      }
    },
    setMarkerDefault: function(marker) {
      return marker.icon = marker.prevIcon;
    },
    applyToMarkers: function() {
      var fargs, markers, serviceFunction;
      serviceFunction = arguments[0], markers = arguments[1], fargs = 3 <= arguments.length ? __slice.call(arguments, 2) : [];
      return markers.forEach(function(marker) {
        return serviceFunction(marker, fargs);
      });
    }
  };
});
