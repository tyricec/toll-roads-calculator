var Marker, app;

Marker = (function() {
  function Marker(id, name, type, latlng, freeway, point_type) {
    this.id = id;
    this.name = name;
    this.type = type;
    this.latlng = latlng;
    this.freeway = freeway;
    this.point_type = point_type;
    this.start = null;
    this.end = null;
    this.displayName = this.freeway + " " + this.name;
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
      this.status = "inactive";
      this.icon = "states/inactive.png";
      this.prevIcon = "states/inactive.png";
    } else {
      this.status = "inactive";
      this.icon = "states/plaza.png";
      this.prevIcon = "states/plaza.png";
    }
    this.showWindow = false;
    this.refresh = true;
  }

  return Marker;

})();

app = angular.module('mapApp', ['google-maps', 'services', 'ui.bootstrap']);

app.controller('infoController', [
  '$scope', 'sharedProperties', function($scope, sharedProperties) {
    var props;
    props = $scope.props = sharedProperties.Properties();
    $scope.onStartClick = function() {
      var id, marker;
      marker = $scope.props.currentMarker;
      id = marker.id;
      if (props.route.end.id === id) {
        sharedProperties.setEnd(0);
      }
      return sharedProperties.setStart(marker);
    };
    $scope.onEndClick = function() {
      var id, marker;
      marker = $scope.props.currentMarker;
      id = marker.id;
      if (props.route.start.id === id) {
        sharedProperties.setStart(0);
      }
      return sharedProperties.setEnd(marker);
    };
    return $scope.onStreetViewClick = function() {
      var currentMarker;
      currentMarker = $scope.props.currentMarker;
      props.panorama.setPosition(currentMarker.glatlng);
      return $scope.$emit('street-view-clicked');
    };
  }
]);

app.controller('mapController', [
  '$scope', '$http', '$compile', 'sharedProperties', 'markerService', function($scope, $http, $compile, sharedProperties, markerService) {
    var preparePeakRates, reduceDropdownOptions;
    $http.get('php/routes.php?method=getRoutes').success(function(points) {
      var allPoints, endPoints, endPoints73, endPointsRest, markerPlazas, points73, pointsRest, startPointRest, startPoints, startPoints73;
      allPoints = [];
      startPoints = [];
      endPoints = [];
      markerPlazas = [];
      points73 = [];
      pointsRest = [];
      startPoints73 = [];
      endPoints73 = [];
      startPointRest = [];
      endPointsRest = [];
      points.forEach(function(element) {
        return (function() {
          var latlng, marker, showPointAccessBtns;
          latlng = {
            'latitude': parseFloat(element.route_lat),
            'longitude': parseFloat(element.route_long)
          };
          marker = new Marker(parseInt(element.route_id), element.route_name, element.route_type, latlng, element.route_fwy, element.route_point_type);
          showPointAccessBtns = function(point) {
            if (point.point_type !== "exit") {
              $scope.map.local.showStartBtn = true;
            } else {
              $scope.map.local.showStartBtn = false;
            }
            if (point.point_type !== "entry") {
              return $scope.map.local.showEndBtn = true;
            } else {
              return $scope.map.local.showEndBtn = false;
            }
          };
          marker.onClick = function() {
            var setMarkersDefault;
            showPointAccessBtns(this.model);
            $scope.map.currentMarker = this.model;
            if ($scope.map.currentMarker.type !== 'plaza') {
              $scope.map.showWindow = true;
            } else {
              $scope.map.showWindow = false;
            }
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
                $scope.map.local.currentMarker = _this.model;
                $scope.id = _this.model.id;
                $scope.typeString = _this.model.typeString;
                $scope.markerTitle = _this.model.name;
                return $scope.$apply();
              };
            })(this));
          };
          if (marker.type === "point") {
            allPoints.push(marker);
          }
          if (marker.type === "point" && marker.point_type !== "exit") {
            startPoints.push(marker);
          }
          if (marker.type === "point" && marker.point_type !== "entry") {
            endPoints.push(marker);
          }
          if (marker.type === "plaza") {
            markerPlazas.push(marker);
          }
          if (marker.freeway === '73' && marker.type === "point") {
            return points73.push(marker);
          } else if (marker.type === "point") {
            return pointsRest.push(marker);
          }
        })();
      });
      return (function() {
        $scope.map.local.points = [];
        $scope.map.local.startPoints = startPoints;
        $scope.map.local.endPoints = endPoints;
        $scope.map.local.plazas = markerPlazas;
        $scope.map.local.startDisplayOpts = [];
        $scope.map.local.endDisplayOpts = [];
        $scope.map.local.points73 = points73;
        $scope.map.local.pointsRest = pointsRest;
        $scope.map.local.startPoints73 = startPoints.filter(function(point) {
          return point.freeway === "73";
        });
        $scope.map.local.endPoints73 = endPoints.filter(function(point) {
          return point.freeway === "73";
        });
        $scope.map.local.startPointsRest = startPoints.filter(function(point) {
          return point.freeway !== "73";
        });
        return $scope.map.local.endPointsRest = endPoints.filter(function(point) {
          return point.freeway !== "73";
        });
      })();
    });
    $scope.map = {
      'center': {
        'latitude': 33.689388,
        'longitude': -117.731235
      },
      'zoom': 11,
      'streetView': {},
      'fitMarkers': false,
      'pan': false,
      'innerElementsLoaded': false,
      'local': sharedProperties.Properties(),
      'showTraffic': false,
      'showStartBtn': true,
      'showStreetView': true,
      'currentMarker': {},
      'showWindow': false,
      'closeWindow': (function() {
        markerService.setMarkerDefault(this.currentMarker);
        return $scope.$apply();
      }),
      'switchPoints': (function() {
        var tempEndPoint, tempStartPoint;
        tempStartPoint = $scope.map.local.route.start;
        tempEndPoint = $scope.map.local.route.end;
        $scope.map.local.route.start = tempEndPoint;
        return $scope.map.local.route.end = tempStartPoint;
      }),
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
      'markerOptions': {
        'visible': true
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
    preparePeakRates = function(peakrates) {
      return peakrates.forEach(function(rate, index) {
        return rate.descriptionId = Array(index + 2).join("*");
      });
    };
    $scope.getRate = function() {
      var rateEl;
      rateEl = angular.element("#calc-results");
      return rateEl.slideUp(200, function() {
        var axles, endId, startId, type;
        startId = $scope.map.local.route.start.id;
        endId = $scope.map.local.route.end.id;
        type = $scope.map.local.route.type;
        axles = $scope.map.local.route.axles;
        return $http.get("php/rates.php?method=getRates&start=" + startId + "&end=" + endId + "&type=" + type + "&axles=" + axles).success(function(resp) {
          var rateObj;
          rateObj = $scope.map.local.route.rateObj = resp;
          if (rateObj.rates != null) {
            if (rateObj.rates.peak != null) {
              preparePeakRates(rateObj.rates.peak);
            }
          }
          return rateEl.slideDown();
        });
      });
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
      points = $scope.map.local.endPoints;
      newPoints = [];
      for (_i = 0, _len = points.length; _i < _len; _i++) {
        point = points[_i];
        if (cond(point)) {
          newPoints.push(point);
        }
      }
      return $scope.map.local.endDisplayOpts = newPoints;
    };
    $scope.$watch('map.local.route.fwy', function(newValue, oldValue, scope) {
      $scope.map.local.route.start = 0;
      $scope.map.local.route.end = 0;
      if (newValue === '73') {
        $scope.map.local.points = $scope.map.local.points73;
        $scope.map.local.startDisplayOpts = $scope.map.local.startPoints73;
        return $scope.map.local.endDisplayOpts = $scope.map.local.endPoints73;
      } else {
        $scope.map.local.points = $scope.map.local.pointsRest;
        $scope.map.local.startDisplayOpts = $scope.map.local.startPointsRest;
        return $scope.map.local.endDisplayOpts = $scope.map.local.endPointsRest;
      }
    });
    return $scope.$watchCollection('map.local.route', function(newValues, oldValues, scope) {
      var endPoints, endPointsOpts, points, startPoints, startPointsOpts;
      points = sharedProperties.Properties().points;
      startPoints = $scope.map.local.startPoints;
      endPoints = $scope.map.local.endPoints;
      if (newValues.fwy === "73" || newValues.fwy === "73") {
        startPointsOpts = $scope.map.local.startPoints73;
        endPointsOpts = $scope.map.local.endPoints73;
      } else {
        startPointsOpts = $scope.map.local.startPointsRest;
        endPointsOpts = $scope.map.local.endPointsRest;
      }
      if ((startPoints == null) || (endPoints == null)) {
        return false;
      }
      points.forEach(function(marker) {
        if (marker.status === "start" || marker.status === "end") {
          return markerService.setMarkerStatus(marker, "inactive");
        }
      });
      $scope.map.local.startDisplayOpts = startPointsOpts.filter(function(point) {
        return point !== newValues.end;
      });
      $scope.map.local.endDisplayOpts = endPointsOpts.filter(function(point) {
        return point !== newValues.start;
      });

      /*
      reduceDropdownOptions( (marker) ->
        return true if newValues.start is ""
        if newValues.start.freeway is "73"
          return marker.freeway is "73" 
        else
          return marker.freeway isnt "73"
      ) unless newValues.start is 0
       */
      sharedProperties.setPoints(points);
      console.log(newValues.start);
      markerService.setMarkerStatus(newValues.start, "start");
      return markerService.setMarkerStatus(newValues.end, "end");
    });
  }
]);
