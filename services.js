// Generated by CoffeeScript 1.7.1
var app;

app = angular.module('services', []);

app.service('sharedProperties', function() {
  var props;
  props = {
    route: {
      start: 0,
      end: 0
    },
    markers: [],
    plazas: [],
    panorama: {}
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
    setMarkers: function(val) {
      return props.markers = val;
    },
    setPlazas: function(val) {
      return props.markers = val;
    },
    setPanorama: function(val) {
      var currentMarker, panoEl;
      currentMarker = props.markers[0];
      panoEl = document.getElementById('pano');
      return props.panorama = new google.maps.StreetViewPanorama(panoEl);
    }
  };
});

app.service('markerService', function() {
  return {
    setMarkerStatus: function(marker, status) {
      if (marker == null) {

      } else {
        console.log("Here");
        marker.status = status;
        if (status === 'focused') {
          marker.showWindow = true;
        }
        if (status !== 'focused') {
          marker.prevIcon = "/states/" + status + ".png";
        }
        return marker.icon = "/states/" + status + ".png";
      }
    },
    setMarkerDefault: function(marker) {
      marker.showWindow = false;
      return marker.icon = marker.prevIcon;
    }
  };
});
