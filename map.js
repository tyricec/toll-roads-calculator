// Generated by CoffeeScript 1.7.1
var Marker, app;

Marker = (function() {
  function Marker(id, name, type, latlng, freeway) {
    this.id = id;
    this.name = name;
    this.type = type;
    this.latlng = latlng;
    this.freeway = freeway;
    this.start = null;
    this.end = null;
    this.glatlng = {
      lat: this.latlng.latitude,
      lng: this.latlng.longitude
    };
    this.icon = "/states/inactive.png";
    this.prevIcon = "/states/inactive.png";
    this.showWindow = false;
    this.refresh = true;
  }

  return Marker;

})();

app = angular.module('mapApp', ['google-maps', 'services']);

app.controller('infoController', [
  '$scope', 'sharedProperties', function($scope, sharedProperties) {
    $scope.onStartClick = function() {
      var id, props;
      props = sharedProperties.Properties();
      id = $scope.model.id;
      if (props.route.end === id) {
        sharedProperties.setEnd(0);
      }
      return sharedProperties.setStart($scope.model.id);
    };
    $scope.onEndClick = function() {
      var id, props;
      props = sharedProperties.Properties();
      id = $scope.model.id;
      if (props.route.start === id) {
        sharedProperties.setStart(0);
      }
      return sharedProperties.setEnd($scope.model.id);
    };
    return $scope.onStreetViewClick = function() {
      var currentMarker, properties;
      properties = sharedProperties.Properties();
      currentMarker = properties.markers[$scope.model.id];
      properties.panorama.setPosition(currentMarker.glatlng);
      return $scope.$emit('street-view-clicked');
    };
  }
]);

app.controller('mapController', [
  '$scope', '$http', '$compile', 'sharedProperties', 'markerService', function($scope, $http, $compile, sharedProperties, markerService) {
    var initMarkers;
    initMarkers = function() {
      return $http.get('/php/routes.php?method=getRoutes').success(function(points) {
        var markers;
        markers = [];
        points.forEach(function(element) {
          return (function() {
            var latlng, marker;
            latlng = {
              'latitude': parseFloat(element.route_lat),
              'longitude': parseFloat(element.route_long)
            };
            marker = new Marker(parseInt(element.route_id), element.route_name, element.route_type, latlng, element.route_fwy);
            marker.close = function() {
              markerService.setMarkerDefault(this.model);
              return $scope.$apply();
            };
            marker.onClick = function() {
              var setMarkersDefault;
              setMarkersDefault = function(cb) {
                $scope.map.local.markers.forEach(function(element) {
                  return (function() {
                    return markerService.setMarkerDefault(element);
                  })();
                });
                return cb();
              };
              return setMarkersDefault((function(_this) {
                return function() {
                  markerService.setMarkerStatus(_this.model, "focused");
                  $scope.id = _this.model.id;
                  return $scope.$apply();
                };
              })(this));
            };
            return markers.push(marker);
          })();
        });
        return (function() {
          return $scope.map.local.markers = markers;
        })();
      });
    };
    initMarkers();
    $scope.map = {
      'center': {
        'latitude': 33.884388,
        'longitude': -117.641235
      },
      'zoom': 12,
      'streetView': {},
      'local': sharedProperties.Properties(),
      'showTraffic': false,
      'showStreetView': true,
      'toggleTrafficLayer': function() {
        return $scope.map.showTraffic = !$scope.map.showTraffic;
      },
      'mapOptions': {
        'panControl': false,
        'rotateControl': false,
        'streetViewControl': false,
        'zoomControlOptions': {
          'position': google.maps.ControlPosition.BOTTOM_LEFT
        }
      },
      'infoWindowOptions': {
        'pixelOffset': new google.maps.Size(0, -30)
      },
      'events': {
        'idle': function(map) {
          var addCloseStreetBtn, addTrafficBtn, loadStreetView;
          addTrafficBtn = function() {
            var el, element;
            element = document.createElement('div');
            el = angular.element(element);
            el.append('<button ng-click="map.toggleTrafficLayer()">Traffic</button>');
            $compile(el)($scope);
            return map.controls[google.maps.ControlPosition.TOP_RIGHT].push(el[0]);
          };
          addCloseStreetBtn = function(callback) {
            var el, element, panorama;
            element = document.createElement('div');
            el = angular.element(element);
            el.append('<button id="closeStreetView" ng-click="map.handleStreetView()">Close</button>');
            $compile(el)($scope);
            panorama = sharedProperties.Properties().panorama;
            panorama.controls[google.maps.ControlPosition.TOP_RIGHT].push(el[0]);
            return callback();
          };
          loadStreetView = function(cb) {
            sharedProperties.setPanorama(map);
            return cb();
          };
          loadStreetView(function() {
            return addCloseStreetBtn(function() {
              return angular.element("#pano").slideToggle(800);
            });
          });
          return addTrafficBtn();
        }
      }
    };
    $scope.$on("street-view-clicked", function() {
      var panoEl;
      panoEl = angular.element("#pano");
      if ($scope.map.showStreetView === true) {
        if (panoEl.css("z-index") !== -1) {
          return panoEl.css("height", 0);
        }
      }
    });
    return $scope.$watchCollection('map.local.route', function(newValues, oldValues, scope) {
      var endId, markers, startId;
      startId = newValues.start;
      endId = newValues.end;
      if ((startId === 0) && (endId === 0) || (startId === endId)) {
        if (oldValues.start === startId) {
          return sharedProperties.setStart(0);
        }
        if (oldValues.end === endId) {
          return sharedProperties.setEnd(0);
        }
      }
      markers = sharedProperties.Properties().markers;
      markers.forEach(function(marker) {
        if (marker.status === "start" || marker.status === "end") {
          return markerService.setMarkerStatus(marker, "inactive");
        }
      });
      sharedProperties.setMarkers(markers);
      markerService.setMarkerStatus(markers[startId - 1], 'start');
      return markerService.setMarkerStatus(markers[endId - 1], 'end');
    });
  }
]);
