React = require('react')
ampersandReactMixin = require 'ampersand-react-mixin'
RequestConfig = require('./browser/request-config')
ResponseInfo = require('./browser/response-info')
ErrorPanel = require('./browser/error-panel')
RunningPanel = require('./browser/running-panel')
DataPanel = require('./data-panel')

# API Browser UI –
module.exports = React.createClass
  displayName: 'ApiBrowser'
  mixins: [ampersandReactMixin]

  onRequestConfigChange: (key, value)->
    @props.browser.requestConfig.set(key, value)

  onRequestSubmit: (event)-> # save config, then run request:
    event.preventDefault()
    @props.browser.save()
    @props.browser.runRequest()

  onClear: ()-> @props.browser.clear()

  render: ()->
    browser = @props.browser

    <div className='app--browser row'>

      <div className='col-md-7'>
        <RequestConfig
          config={browser.requestConfig}
          onSubmit={@onRequestSubmit}
          onClear={@onClear}
          onConfigChange={@onRequestConfigChange}/>
        {switch
          when (roaObject = browser.response?.roaObject)?
            <DataPanel title="ROA Parsed"
              text={require('js-yaml').safeDump(roaObject.serialize())}/>
          when (roaError = browser.response?.roaError)?
            <ErrorPanel title="ROA Error!"
              errorText={roaError}/>
        }
      </div>

      <div className='col-md-5'>
        {switch
          when browser.response?.error?
            <ErrorPanel title='Request Error!'
              errorText={browser.response.error}/>
          when browser.response?
            <ResponseInfo response={browser.response}/>
          when browser.currentRequest?
            <RunningPanel/>
          else
            <div/>
        }
      </div>
    </div>
