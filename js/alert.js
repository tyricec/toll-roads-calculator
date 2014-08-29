var app;

app = angular.module("Alert", ['services']);

app.controller("AlertController", [
  'sharedProperties', '$scope', '$timeout', function(sharedProperties, $scope, $timeout) {
    $scope.local = sharedProperties.Properties();
    return $scope.$watch('local.showMapAlert', function(newValue, oldValue) {
      if (newValue === false) {
        return false;
      }
      return $timeout((function() {
        return $scope.local.showMapAlert = false;
      }), 6000);
    });
  }
]);
