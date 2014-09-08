var app,
  __slice = [].slice;

app = angular.module('services', []);

app.service('sharedProperties', [
  'markerService', function(markerService) {
    var props;
    props = {
      route: {
        fwy: '',
        start: null,
        end: null,
        type: 'onetime',
        axles: 2
      },
      mapControl: {},
      mapObj: {},
      points: [],
      plazas: [],
      panorama: {},
      types: [
        {
          "id": "onetime",
          "displayName": 'One-Time-Toll'
        }, {
          "id": "fastrak",
          "displayName": 'Fastrak'
        }, {
          "id": 'express',
          "displayName": "ExpressAccount"
        }
      ],
      onetimetype: [
        {
          "id": "onetime",
          "displayName": 'One-Time-Toll'
        }
      ],
      displayTypes: [],
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
        if (scope.map.showWindow || scope.map.showPlazaWindow) {
          markerService.setMarkerDefault(scope.map.currentMarker);
          scope.map.showWindow = false;
          scope.map.showPlazaWindow = false;
          if (!scope.$$phase) {
            return scope.$apply();
          }
        }
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
