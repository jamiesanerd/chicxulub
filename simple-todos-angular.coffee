onReady = ->
  angular.bootstrap document, [ 'simple-todos' ]
  return

Tasks = new (Mongo.Collection)('tasks')
if Meteor.isClient
  # This code only runs on the client
  angular.module 'simple-todos', [ 'angular-meteor' ]
  if Meteor.isCordova
    angular.element(document).on 'deviceready', onReady
  else
    angular.element(document).ready onReady

  angular.module('simple-todos').config(['$interpolateProvider', ($interpolateProvider) ->
    $interpolateProvider.startSymbol('[[')
    $interpolateProvider.endSymbol(']]')
  ])

  angular.module('simple-todos').controller('TodosListCtrl', ['$scope', '$rootScope', '$meteor', ($scope, $rootScope, $meteor) ->
      $scope.$meteorSubscribe 'tasks'
      $scope.tasks = $meteor.collection(->
        Tasks.find $scope.getReactively('query'), sort: createdAt: -1
      )

      $scope.addTask = (newTask) ->
        $meteor.call 'addTask', newTask
        return

      $scope.deleteTask = (task) ->
        $meteor.call 'deleteTask', task._id
        return

      $scope.setChecked = (task) ->
        $meteor.call 'setChecked', task._id, !task.checked
        return

      $scope.setPrivate = (task) ->
        $meteor.call 'setPrivate', task._id, !task.private
        return

      $scope.$watch 'hideCompleted', ->
        if $scope.hideCompleted
          $scope.query = checked: $ne: true
        else
          $scope.query = {}
        return

      $scope.cardColor = (task) ->
        if task.owner != $rootScope.currentUser._id
          return "grey"
        else if task.private
          return "red lighten-2"
        else
          return "teal lighten-2"

      $scope.incompleteCount = ->
        Tasks.find(checked: $ne: true).count()

      return
  ])
  Accounts.ui.config passwordSignupFields: 'USERNAME_ONLY'

# Meteor methods
Meteor.methods
  addTask: (text) ->
    # Make sure the user is logged in before inserting a task
    if !Meteor.userId()
      throw new (Meteor.Error)('not-authorized')
    Tasks.insert
      text: text
      createdAt: new Date
      owner: Meteor.userId()
      username: Meteor.user().username
    return
  deleteTask: (taskId) ->
    task = Tasks.findOne(taskId)
    if task.private and task.owner != Meteor.userId()
      # If the task is private, make sure only the owner can delete it
      throw new (Meteor.Error)('not-authorized')
    Tasks.remove taskId
    return
  setChecked: (taskId, setChecked) ->
    task = Tasks.findOne(taskId)
    if task.private and task.owner != Meteor.userId()
      # If the task is private, make sure only the owner can check it off
      throw new (Meteor.Error)('not-authorized')
    Tasks.update taskId, $set: checked: setChecked
    return
  setPrivate: (taskId, setToPrivate) ->
    task = Tasks.findOne(taskId)
    # Make sure only the task owner can make a task private
    if task.owner != Meteor.userId()
      throw new (Meteor.Error)('not-authorized')
    Tasks.update taskId, $set: private: setToPrivate
    return

# Server Code
if Meteor.isServer
  Meteor.publish 'tasks', ->
    Tasks.find({$or: [
      { private: $ne: true }
      { owner: @userId }
    ]})
