onReady = ->
  angular.bootstrap document, [ 'sequencer' ]
  return

Tasks = new (Mongo.Collection)('tasks')
if Meteor.isClient
  # This code only runs on the client
  angular.module 'sequencer', [ 'angular-meteor' ]

  angular.module('sequencer').config(['$interpolateProvider', ($interpolateProvider) ->
    $interpolateProvider.startSymbol('[[')
    $interpolateProvider.endSymbol(']]')
  ])

  angular.module('sequencer').controller('SequencerCtrl', ['$scope', '$http', '$meteor', ($scope, $http, $meteor) ->

      @getUser = (username) ->
        if username
          url = 'https://api.github.com/users/' + username + '/events/public'

          $http.get(url).then(
            (response) ->
              $scope.events = response.data

          )

      return @
  ])
