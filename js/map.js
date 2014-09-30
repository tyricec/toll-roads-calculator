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
    if (this.freeway === "73") {
      this.displayName = this.name;
    } else {
      this.displayName = this.freeway + " -- " + this.name;
    }
    this.typeString = "SR " + this.freeway;
    if (this.type !== "plaza") {
      this.markerType = "Access Point:";
    } else {
      this.markerType = "Midway Toll Point:";
    }
    this.glatlng = {
      lat: this.latlng.latitude,
      lng: this.latlng.longitude
    };
    this.maplatlng = new google.maps.LatLng(this.glatlng.lat, this.glatlng.lng);
    this.markerOptions = {
      'optimized': true
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
    if (this.point_type !== "exit") {
      this.showStartBtn = true;
    } else {
      this.showStartBtn = true;
    }
    if (this.point_type !== "entry") {
      this.showEndBtn = true;
    } else {
      this.showEndBtn = true;
    }
  }

  return Marker;

})();

app = angular.module('mapApp', ['google-maps', 'services', 'ui.bootstrap', 'Alert']);

app.controller('mapController', [
  '$scope', '$http', '$compile', 'sharedProperties', 'markerService', function($scope, $http, $compile, sharedProperties, markerService) {
    var formValidated, handleStreetView, isUnknown, preparePeakRates, reduceDropdownOptions, reduceToOneTime, setAllTypes, showAlert, switchablePoint;
    $http.get('php/routes.php?method=getRoutes').success(function(points) {
      var allPoints, endPoints, endPoints73, endPointsRest, markerPlazas, markerPlazas73, markerPlazasRest, points73, pointsRest, startPointRest, startPoints, startPoints73;
      allPoints = [];
      startPoints = [];
      endPoints = [];
      markerPlazas = [];
      markerPlazas73 = [];
      markerPlazasRest = [];
      points73 = [];
      pointsRest = [];
      startPoints73 = [];
      endPoints73 = [];
      startPointRest = [];
      endPointsRest = [];
      points.forEach(function(element) {
        return (function() {
          var latlng, marker;
          latlng = {
            'latitude': parseFloat(element.route_lat),
            'longitude': parseFloat(element.route_long)
          };
          marker = new Marker(parseInt(element.route_id), element.route_name, element.route_type, latlng, element.route_fwy, element.route_point_type);
          marker.onClick = function() {
            var setMarkersDefault;
            $scope.showStartBtn = this.model.showStartBtn;
            $scope.showEndBtn = this.model.showEndBtn;
            $scope.map.currentMarker = this.model;
            if (($scope.map.local.route.start != null) && (this.model.id === $scope.map.local.route.start.id) || (this.model.point_type === "exit")) {
              angular.element(".start-btn").attr('disabled', true);
            } else {
              angular.element(".start-btn").attr('disabled', false);
            }
            if (($scope.map.local.route.end != null) && (this.model.id === $scope.map.local.route.end.id) || (this.model.point_type === "entry")) {
              angular.element(".end-btn").attr('disabled', true);
            } else {
              angular.element(".end-btn").attr('disabled', false);
            }
            if (this.model.type === "point") {
              $scope.map.showWindow = true;
              $scope.map.showPlazaWindow = false;
            } else {
              $scope.map.showWindow = false;
              $scope.map.showPlazaWindow = true;
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
                $scope.markerType = _this.model.markerType;
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
          if (marker.freeway === '73') {
            if (marker.type === "point") {
              return points73.push(marker);
            } else {
              return markerPlazas73.push(marker);
            }
          } else if (marker.type === "point") {
            return pointsRest.push(marker);
          } else {
            return markerPlazasRest.push(marker);
          }
        })();
      });
      return (function() {
        $scope.map.local.startPoints = startPoints;
        $scope.map.local.endPoints = endPoints;
        $scope.map.local.startDisplayOpts = [];
        $scope.map.local.endDisplayOpts = [];
        $scope.map.local.points73 = points73;
        $scope.map.local.pointsRest = pointsRest;
        $scope.map.local.plazas73 = markerPlazas73;
        $scope.map.local.plazasRest = markerPlazasRest;
        $scope.map.local.startPoints73 = startPoints.filter(function(point) {
          return point.freeway === "73";
        });
        $scope.map.local.endPoints73 = endPoints.filter(function(point) {
          return point.freeway === "73";
        });
        $scope.map.local.startPointsRest = startPoints.filter(function(point) {
          return point.freeway !== "73";
        });
        $scope.map.local.endPointsRest = endPoints.filter(function(point) {
          return point.freeway !== "73";
        });
        return $scope.map.local.route.fwy = "rest";
      })();
    });
    switchablePoint = function(point) {
      if (((point != null) && point.point_type === "entry/exit") || (point == null)) {
        return true;
      }
      return false;
    };
    $scope.map = {
      'center': {
        'latitude': 33.689388,
        'longitude': -117.731235
      },
      'zoom': 11,
      'streetView': {},
      'fitMarkers': false,
      'pan': false,
      'control': {},
      'innerElementsLoaded': false,
      'local': sharedProperties.Properties(),
      'showTraffic': false,
      'showStartBtn': true,
      'showStreetView': true,
      'startDisabled': false,
      'endDisabled': false,
      'currentMarker': {},
      'showWindow': false,
      'showPlazaWindow': false,
      'showFwyRest': true,
      'showFwy73': false,
      'closeWindow': (function() {
        return $scope.map.local.closeWindow($scope);
      }),
      'switchPoints': (function() {
        var tempEndPoint, tempStartPoint;
        tempStartPoint = $scope.map.local.route.start;
        tempEndPoint = $scope.map.local.route.end;
        if (!(switchablePoint(tempStartPoint)) || !(switchablePoint(tempEndPoint))) {
          console.log(switchablePoint(tempEndPoint));
          console.log(switchablePoint(tempStartPoint));
          return showAlert('Reverse Trip cannot be completed. One of your selections is a one-way access point and cannot be swtiched.');
        }
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
        'scrollwheel': false,
        'mapTypeControl': false,
        'maxZoom': 16,
        'minZoom': 11,
        'zoomControlOptions': {
          'position': google.maps.ControlPosition.BOTTOM_LEFT
        }
      },
      'infoWindowOptions': {
        'pixelOffset': new google.maps.Size(0, -30)
      },
      'restLayerOptions': {
        'url': 'http://ditisfl.org/toll-roads-calculator/kml/TCA_Toll_Roads_090514_Projec-133_241_261.kml'
      },
      'layer73Options': {
        'url': 'http://ditisfl.org/toll-roads-calculator/kml/TCA_Toll_Roads_090514_Projec-73.kml'
      },
      'events': {
        'idle': function(map) {
          var addCloseStreetBtn, addTrafficBtn, loadStreetView;
          if (!$scope.map.innerElementsLoaded) {
            addTrafficBtn = function() {
              var el, element;
              element = document.createElement('div');
              el = angular.element(element);
              el.append('<button class="btn btn-default btn-custom btn-blue" ng-click="map.toggleTrafficLayer()">Live Traffic</button>');
              $compile(el)($scope);
              return map.controls[google.maps.ControlPosition.TOP_RIGHT].push(el[0]);
            };
            addCloseStreetBtn = function(callback) {
              var el, element, panorama;
              element = document.createElement('div');
              el = angular.element(element);
              el.append('<button id="closeStreetView" class="btn btn-default btn-custom btn-blue" ng-click="map.closeStreetView()">Close Street View</button>');
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
    showAlert = function(message) {
      $("#map-alert").html(message);
      $scope.map.local.showMapAlert = true;
      return false;
    };
    preparePeakRates = function(peakrates) {
      return peakrates.forEach(function(rate, index) {
        return rate.descriptionId = Array(index + 2).join("*");
      });
    };
    formValidated = function() {
      if ($scope.map.local.route.start == null) {
        return false;
      }
      if ($scope.map.local.route.end == null) {
        return false;
      }
      if ($scope.map.local.route.type == null) {
        return false;
      }
      if ($scope.map.local.route.axles == null) {
        return false;
      }
      return true;
    };
    $scope.getRate = function() {
      var rateEl;
      if (!formValidated()) {
        return showAlert('Calculate Your Toll cannot be completed.  Start and end points must be selected to get a toll rate.');
      }
      rateEl = angular.element("#calculator-results");
      rateEl.slideUp(200, function() {
        var axles, endId, startId, type;
        startId = $scope.map.local.route.start.id;
        endId = $scope.map.local.route.end.id;
        type = $scope.map.local.route.type;
        axles = $scope.map.local.route.axles;
        return $http.get("php/rates.php?method=getRates&start=" + startId + "&end=" + endId + "&type=" + type + "&axles=" + axles).success(function(resp) {
          var panoEl, rateObj;
          $scope.map.local.route.offPeakText = resp.payment === "One-Time-Toll" ? "One-Time-Toll" : "Off Peak";
          panoEl = angular.element("#calculator-results div");
          if (resp.rates.off_peak === "No Toll") {
            panoEl.hide();
            $scope.map.local.route.resultText = "No toll required for this trip";
          } else {
            rateObj = $scope.map.local.route.rateObj = resp;
            $scope.map.local.route.resultText = "Your toll for this one-way trip:";
            panoEl.show();
            if (rateObj.rates != null) {
              if (rateObj.rates.peak != null) {
                preparePeakRates(rateObj.rates.peak);
              }
            }
          }
          return rateEl.slideDown();
        });
      });
      return true;
    };
    handleStreetView = function() {
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
        panoEl.animate({
          "height": "55%"
        });
      }
      return true;
    };
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
    isUnknown = function(value) {
      var unknownRegX;
      if (value == null) {
        return false;
      }
      unknownRegX = new RegExp(/unknown/i);
      if (unknownRegX.test(value.name)) {
        return true;
      }
      return false;
    };
    reduceToOneTime = function() {
      return $scope.map.local.displayTypes.forEach(function(type, index) {
        $scope.map.local.route.type = "onetime";
        if (type.id !== "onetime") {
          $scope.map.local.displayTypes = [];
          return $scope.map.local.displayTypes = $scope.map.local.onetimetype;
        }
      });
    };
    setAllTypes = function() {
      $scope.map.local.displayTypes = [];
      return $scope.map.local.types.forEach(function(type) {
        return $scope.map.local.displayTypes.push(type);
      });
    };
    $scope.$watch('map.local.route.fwy', function(newValue, oldValue, scope) {
      $scope.map.local.route.start = null;
      $scope.map.local.route.end = null;
      if (newValue === '73') {
        $scope.map.local.points = $scope.map.local.points73;
        $scope.map.local.plazas = $scope.map.local.plazas73;
        $scope.map.local.startDisplayOpts = $scope.map.local.startPoints73;
        $scope.map.local.endDisplayOpts = $scope.map.local.endPoints73;
        $scope.map.showFwy73 = true;
        $scope.map.showFwyRest = false;
      } else {
        $scope.map.local.points = $scope.map.local.pointsRest;
        $scope.map.local.plazas = $scope.map.local.plazasRest;
        $scope.map.local.startDisplayOpts = $scope.map.local.startPointsRest;
        $scope.map.local.endDisplayOpts = $scope.map.local.endPointsRest;
        $scope.map.showFwy73 = false;
        $scope.map.showFwyRest = true;
      }
      return $scope.map.local.fitBounds();
    });
    $scope.$watchCollection('map.local.route', function(newValues, oldValues, scope) {
      var endPoints, endPointsOpts, points, startPoints, startPointsOpts;
      points = sharedProperties.Properties().points;
      startPoints = $scope.map.local.startPoints;
      endPoints = $scope.map.local.endPoints;
      if (isUnknown(newValues.start) || isUnknown(newValues.end)) {
        reduceToOneTime();
      } else {
        setAllTypes();
      }
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
      sharedProperties.setPoints(points);
      markerService.setMarkerStatus(newValues.start, "start");
      markerService.setMarkerStatus(newValues.end, "end");
      if ($scope.map.local.currentMarker != null) {
        markerService.setMarkerDefault($scope.map.local.currentMarker);
      }
      $scope.map.local.closeWindow($scope);
      return $scope.map.local.fitBounds();
    });
    $scope.onStartClick = function() {
      var id, marker;
      marker = $scope.map.local.currentMarker;
      id = marker.id;
      if ($scope.map.local.route.end != null) {
        if ($scope.map.local.route.end.id === id) {
          sharedProperties.setEnd(null);
        }
      }
      sharedProperties.setStart(marker);
      $scope.map.local.fitBounds();
      return $scope.map.local.closeWindow($scope);
    };
    $scope.onEndClick = function() {
      var id, marker;
      marker = $scope.map.local.currentMarker;
      id = marker.id;
      if ($scope.map.local.route.start != null) {
        if ($scope.map.local.route.start.id === id) {
          sharedProperties.setStart(null);
        }
      }
      sharedProperties.setEnd(marker);
      $scope.map.local.fitBounds();
      return $scope.map.local.closeWindow($scope);
    };
    return $scope.onStreetViewClick = function() {
      var currentMarker;
      currentMarker = $scope.map.local.currentMarker;
      $scope.map.local.panorama.setPosition(currentMarker.glatlng);
      return handleStreetView();
    };
  }
]);
