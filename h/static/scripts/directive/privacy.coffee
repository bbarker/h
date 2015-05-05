module.exports = ['localStorage', 'permissions', '$rootScope', (localStorage, permissions, $rootScope) ->
  VISIBILITY_KEY ='hypothesis.visibility'
  VISIBILITY_PUBLIC = 'public'
  VISIBILITY_PRIVATE = 'private'
  VISIBILITY_GROUP = 'group'

  levels = [
    {name: VISIBILITY_PUBLIC, text: 'Public', icon:'h-icon-public'}
    {name: VISIBILITY_PRIVATE, text: 'Only Me', icon:'h-icon-lock'}
  ]

  getLevel = (name) ->
    for level in levels
      if level.name == name
        return level
    undefined

  isPublic  = (level) -> level == VISIBILITY_PUBLIC

  isGroup  = (level) -> 
    level != ( VISIBILITY_PRIVATE or VISIBILITY_PUBLIC )

  link: (scope, elem, attrs, controller) ->
    return unless controller?

    controller.$formatters.push (selectedPermissions) ->
      return unless selectedPermissions?

      if permissions.isPublic(selectedPermissions)
        getLevel(VISIBILITY_PUBLIC)
      else if permissions.isGroup(selectedPermissions)
        getLevel(VISIBILITY_GROUP)
      else
        getLevel(VISIBILITY_PRIVATE)

    controller.$parsers.push (privacy) ->
      return unless privacy?

      if isPublic(privacy.name)
        newPermissions = permissions.public()
      else if isGroup(privacy.name)
        newPermissions = permissions.group()
      else
        newPermissions = permissions.private()

      # Cannot change the $modelValue into a new object
      # Just update its properties
      for key,val of newPermissions
        controller.$modelValue[key] = val

      controller.$modelValue

    controller.$render = ->
      unless controller.$modelValue.read?.length
        name = localStorage.getItem VISIBILITY_KEY
        if $rootScope.currentview == 'All'
          name ?= VISIBILITY_PUBLIC
        else
          name ?= VISIBILITY_GROUP
        level = getLevel(name)
        controller.$setViewValue level

      scope.level = controller.$viewValue

    scope.levels = levels
    scope.setLevel = (level) ->
      localStorage.setItem VISIBILITY_KEY, level.name
      controller.$setViewValue level
      controller.$render()
    scope.isPublic = isPublic
    scope.isGroup = isGroup

    scope.$watch (-> $rootScope.views), (views) ->
      for view in $rootScope.views
        if view.name != 'All'
          levels.push {name: VISIBILITY_GROUP, text: view.name, icon:'h-icon-group'}

  require: '?ngModel'
  restrict: 'E'
  scope: {}
  templateUrl: 'privacy.html'
]
