###*
# @ngdoc service
# @name  Permissions
#
# @description
# This service can set default permissions to annotations properly and
# offers some utility functions regarding those.
###
module.exports = ['auth', (auth) ->
  ALL_PERMISSIONS = {}
  GROUP_WORLD = 'group:__world__'
  LINK_ONLY = 'group:'
  ADMIN_PARTY = [{
    allow: true
    principal: GROUP_WORLD
    action: ALL_PERMISSIONS
  }]

  # Creates access control list from context.permissions
  _acl = (context) ->
    parts =
      for action, roles of context.permissions or []
        for role in roles
          allow: true
          principal: role
          action: action

    if parts.length
      Array::concat parts...
    else
      ADMIN_PARTY

  ###*
  # @ngdoc method
  # @name permissions#private
  #
  # Sets permissions for a private annotation
  # Typical use: annotation.permissions = permissions.private()
  ###
  private: ->
    read: [auth.user]
    update: [auth.user]
    delete: [auth.user]
    admin: [auth.user]

  ###*
  # @ngdoc method
  # @name permissions#private
  #
  # Sets permissions for a public annotation
  # Typical use: annotation.permissions = permissions.public()
  ###
  public: ->
    read: [GROUP_WORLD]
    update: [auth.user]
    delete: [auth.user]
    admin: [auth.user]

  ###*
  # @ngdoc method
  # @name permissions#private
  #
  # Sets permissions for a public annotation
  # Typical use: annotation.permissions = permissions.public()
  ###
  group: ->
    read: [LINK_ONLY]
    update: [auth.user]
    delete: [auth.user]
    admin: [auth.user]

  ###*
  # @ngdoc method
  # @name permissions#isPublic
  #
  # @param {Object} permissions
  #
  # This function determines whether the permissions allow public visibility
  ###
  isPublic: (permissions) ->
    GROUP_WORLD in (permissions?.read or [])

  ###*
  # @ngdoc method
  # @name permissions#isGroup
  #
  # @param {Object} permissions
  #
  # This function determines whether the permissions allow public visibility
  ###
  isGroup: (permissions) ->
    LINK_ONLY in (permissions?.read or [])

  ###*
  # @ngdoc method
  # @name permissions#isPrivate
  #
  # @param {Object} permissions
  # @param {String} user
  #
  # @returns {boolean} True if the annotation is private to the user.
  ###
  isPrivate: (permissions, user) ->
    user and angular.equals(permissions?.read or [], [user])

  ###*
  # @ngdoc method
  # @name permissions#permits
  #
  # @param {String} action action to authorize (read|update|delete|admin)
  # @param {Object} context to permit action on it or not
  # @param {String} user the userId
  #
  # User access-level-control function
  ###
  permits: (action, context, user) ->
    acl = _acl context

    for ace in acl
      if ace.principal not in [user, GROUP_WORLD]
        continue
      if ace.action not in [action, ALL_PERMISSIONS]
        continue
      return ace.allow

    false
]
