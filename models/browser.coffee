# browser Model - browser.js
Model = require('ampersand-state')
app = require('ampersand-app')
parseHeaders = require('parse-headers')
hashchange = require('hashchange')
urlQuery = require('qs')
f = require('../lib/fun')
curl = require('../lib/curl')

RequestConfig = require('./request-config')
Response = require('./response')

module.exports = Model.extend
  DEFAULTS: ()-> app.DEFAULTS

  # props: NOTE: the browser has no 'props', only children, session and methods.

  # children: nested state; NOTE: instances are never swapped out, only changed!
  children:
    requestConfig: RequestConfig

  # properties that are only local (never serialized)
  # NOTE: When type=state, instances will be swapped out regularly (and change!)
  session:
    formAction: 'object'
    currentRequest: 'object'
    lastRequest: 'object'
    response: Response

  # run on 'create' when option parse=true
  parse: (data) ->
    # takes request config as a query-string (typically from url hash)
    if typeof data is 'string'
      return {requestConfig: (try urlQuery.parse(data))}

  # instance methods:
  save: ()->
    # add and remove event listener to not trigger while saving
    hashchange.unbind(app.onHashChange)
    hashchange.updateHash(urlQuery.stringify(@requestConfig.serialize()))
    setTimeout((-> hashchange.update(app.onHashChange)), 10) # "next tick"

  clear: () ->
    @currentRequest?.curl.abort()
    @requestConfig.clear()
    Model::clear.call(@)

  onRequestSubmit: (url)->
    @requestConfig.set('url', url) if url?
    @save()
    @runRequest()

  runFormActionRequest: (config)->
    # build config from submitted form, current formAction und main request
    config = f.defaults {}, config, @formAction, @requestConfig.serialize()
    # clear the form and execute request
    @formAction = null
    @runRequest(config)

  runRequest: (extraConfig = {})->
    config = f({})
      .defaults(extraConfig, @requestConfig.serialize(),
        method: 'GET'
        # username: @requestConfig.user
        # password: @requestConfig.pass
      )
      .merge(
        headers: (try parseHeaders(@requestConfig.headers))
      ,
        headers: (try parseHeaders(extraConfig.headers))
        body: (try JSON.parse(extraConfig.body))
      )
      .value()

    # reset current request
    @response = null
    if @currentRequest?
      @currentRequest.curl.abort()
      @currentRequest = null

    # run and keep reference (with time), build new response when finished:
    @currentRequest = f.assign {started: (new Date().getTime())},
      curl: curl config, (err, res)=>
        @lastRequest = @currentRequest
        @currentRequest = null
        @response = unless err
          new Response(f.assign({}, res, {requestConfig: config}))
        else
          new Response(error: err.toString())
