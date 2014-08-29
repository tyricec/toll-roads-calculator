app = angular.module "Alert", ['services']

app.controller "AlertController", ['sharedProperties', '$scope', '$timeout', (sharedProperties, $scope, $timeout) ->

  $scope.local = sharedProperties.Properties()

  $scope.$watch 'local.showMapAlert', (newValue, oldValue) ->
    return false if newValue is false
    $timeout( (-> $scope.local.showMapAlert = false), 6000)
      
  
]