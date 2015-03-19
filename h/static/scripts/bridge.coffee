$ = require('jquery')
Channel = require('jschannel')

# The Bridge service sets up a channel between frames
# and provides an events API on top of it.
class Bridge
  # Connected links to other frames
  links: null
  channelListeners: null
  onConnectListeners: null

  constructor: ->
    @links = []
    @channelListeners = {}
    @onConnectListeners = []

  createChannel: (source, origin, scope) ->
    # Set up a channel
    channelOptions =
      window: source
      origin: origin
      scope: scope
      onReady: (channel) =>
        for callback in @onConnectListeners
          callback.call(this, channel, source)
    channel = this._buildChannel channelOptions

    # Attach channel message listeners
    for own method, callback of @channelListeners
      channel.bind method, callback

    # Store the newly created channel in our collection
    @links.push
      channel: channel
      window: source

    channel

  # Make a method call on all links, collect the results and pass them to a
  # callback when all results are collected. Parameters:
  # - options.method (required): name of remote method to call
  # - options.params: parameters to pass to remote method
  # - options.callback: called with array of results
  call: (options) ->
    _makeDestroyFn = (c) =>
      (error, reason) =>
        c.destroy()
        @links = (l for l in @links when l.channel isnt c)

    deferreds = @links.map (l) ->
      d = $.Deferred().fail(_makeDestroyFn l.channel)
      callOptions = {
        method: options.method
        params: options.params
        success: (result) -> d.resolve result
        error: (error, reason) ->
          if error isnt 'timeout_error'
            d.reject error, reason
          else
            d.resolve null
        timeout: 1000
      }
      l.channel.call callOptions
      d.promise()

    $.when(deferreds...)
    .then (results...) =>
      options.callback? null, results
    .fail (failure) =>
      options.callback? failure

  # Publish a notification to all links
  notify: (options) ->
    for l in @links
      l.channel.notify options
    return

  on: (method, callback) ->
    if @channelListeners[method]
      throw new Error("Listener '#{method}' already bound in Bridge")

    @channelListeners[method] = callback
    for l in @links
      l.channel.bind method, callback
    return this

  off: (method) ->
    for l in @links
      l.channel.unbind method
    delete @channelListeners[method]
    return this

  # Add a function to be called upon a new connection
  onConnect: (callback) ->
    @onConnectListeners.push(callback)
    this

  # Construct a channel to another frame
  _buildChannel: (options) ->
    # jschannel chokes on FF and Chrome extension origins.
    if (options.origin.match /^chrome-extension:\/\//) or
        (options.origin.match /^resource:\/\//)
      options = $.extend {}, options, {origin: '*'}
    channel = Channel.build(options)

if angular?
  angular.module('h').service 'bridge', Bridge
else
  Annotator.Plugin.CrossFrame.Bridge = Bridge
