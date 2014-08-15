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
    if (this.type !== "plaza") {
      this.typeString = "Access Point: CA " + this.freeway;
    } else {
      this.typeString = "Plaza: CA " + this.freeway;
    }
    this.glatlng = {
      lat: this.latlng.latitude,
      lng: this.latlng.longitude
    };
    if (this.type !== "plaza") {
      this.icon = "/states/inactive.png";
      this.prevIcon = "/states/inactive.png";
    } else {
      this.icon = "/states/plaza.png";
      this.prevIcon = "/states/plaza.png";
    }
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
      return sharedProperties.setStart($scope.model);
    };
    $scope.onEndClick = function() {
      var id, props;
      props = sharedProperties.Properties();
      id = $scope.model.id;
      if (props.route.start === id) {
        sharedProperties.setStart(0);
      }
      return sharedProperties.setEnd($scope.model);
    };
    return $scope.onStreetViewClick = function() {
      var currentMarker, properties;
      properties = sharedProperties.Properties();
      currentMarker = $scope.model;
      properties.panorama.setPosition(currentMarker.glatlng);
      return $scope.$emit('street-view-clicked');
    };
  }
]);

app.controller('mapController', [
  '$scope', '$http', '$compile', 'sharedProperties', 'markerService', function($scope, $http, $compile, sharedProperties, markerService) {
    var initMarkers, reduceDropdownOptions;
    initMarkers = function() {
      return $http.get('/php/routes.php?method=getRoutes').success(function(points) {
        var markerPlazas, markerPoints;
        markerPoints = [];
        markerPlazas = [];
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
                $scope.map.local.points.forEach(function(element) {
                  return (function() {
                    return markerService.setMarkerDefault(element);
                  })();
                });
                $scope.map.local.plazas.forEach(function(element) {
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
                  $scope.typeString = _this.model.typeString;
                  $scope.markerTitle = _this.model.name;
                  return $scope.$apply();
                };
              })(this));
            };
            if (marker.type === "point") {
              return markerPoints.push(marker);
            } else {
              return markerPlazas.push(marker);
            }
          })();
        });
        return (function() {
          $scope.map.local.points = markerPoints;
          $scope.map.local.plazas = markerPlazas;
          return $scope.map.local.displayPoints = markerPoints;
        })();
      });
    };
    initMarkers();
    $scope.map = {
      'center': {
        'latitude': 33.689388,
        'longitude': -117.731235
      },
      'zoom': 11,
      'streetView': {},
      'innerElementsLoaded': false,
      'local': sharedProperties.Properties(),
      'showTraffic': false,
      'showStreetView': true,
      'closeStreetView': (function() {
        var panoEl;
        panoEl = angular.element('#pano');
        panoEl.animate({
          "height": 0
        }, {
          "complete": function() {
            return $scope.map.showStreetView = false;
          }
        });
        return true;
      }),
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
          if (!$scope.map.innerElementsLoaded) {
            angular.element('.infoWindow').show();
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
              el.append('<button id="closeStreetView" ng-click="map.closeStreetView()">Close</button>');
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
                return $scope.map.innerElementsLoaded = true;
              });
            });
            return addTrafficBtn();
          }
        }
      }
    };
    $scope.$on("street-view-clicked", function() {
      var panoEl;
      panoEl = angular.element("#pano");
      if ($scope.map.showStreetView === true && panoEl.css('z-index') === "-1") {
        panoEl.css({
          "z-index": 1,
          "height": 0
        });
        panoEl.hide();
        $scope.map.showStreetView = false;
      }
      if ($scope.map.showStreetView === false) {
        $scope.map.showStreetView = true;
        panoEl.show();
        return panoEl.animate({
          "height": "45%"
        });
      }
    });
    reduceDropdownOptions = function(cond) {
      var newPoints, point, points, _i, _len;
      points = $scope.map.local.points;
      newPoints = [];
      for (_i = 0, _len = points.length; _i < _len; _i++) {
        point = points[_i];
        if (cond(point)) {
          newPoints.push(point);
        }
      }
      return $scope.map.local.displayPoints = newPoints;
    };
    return $scope.$watchCollection('map.local.route', function(newValues, oldValues, scope) {
      var endPoint, points, startPoint, startPointChanged;
      if (newValues.start === null) {
        newValues.start = 0;
        $scope.map.local.points.forEach(function(marker) {
          if (marker.status !== "end") {
            return markerService.setMarkerStatus(marker, "inactive");
          }
        });
      }
      if (newValues.end === null) {
        newValues.end = 0;
        $scope.map.local.points.forEach(function(marker) {
          if (marker.status !== "start") {
            return markerService.setMarkerStatus(marker, "inactive");
          }
        });
      }
      if (newValues.start.freeway === "73" && newValues.end.freeway !== "73") {
        newValues.end = 0;
      } else if (newValues.start.freeway !== "73" && newValues.end.freeway === "73") {
        newValues.end = 0;
      }
      startPointChanged = (oldValues.start.id !== newValues.start.id) || (oldValues.start.id == null) || (newValues.start.id == null);
      startPoint = newValues.start;
      endPoint = newValues.end;
      if ((startPoint === 0) && (endPoint === 0) || (startPoint.id === endPoint.id)) {
        points = $scope.map.local.points;
        console.log(startPoint === endPoint && startPoint === 0);
        if ((startPoint === 0) && (endPoint === 0)) {
          $scope.map.local.displayPoints = points;
        }
        if (oldValues.start.id === startPoint.id) {
          return sharedProperties.setStart(0);
        }
        if (oldValues.end.id === endPoint.id) {
          return sharedProperties.setEnd(0);
        }
      }
      points = sharedProperties.Properties().points;
      points.forEach(function(marker) {
        if (marker.status === "start" || marker.status === "end") {
          return markerService.setMarkerStatus(marker, "inactive");
        }
      });
      reduceDropdownOptions(function(marker) {
        if (startPoint === "") {
          return true;
        }
        if (startPoint.freeway === "73") {
          return marker.freeway === "73";
        } else {
          return marker.freeway !== "73";
        }
      });
      sharedProperties.setPoints(points);
      markerService.setMarkerStatus(startPoint, "start");
      return markerService.setMarkerStatus(endPoint, "end");
    });
  }
]);
