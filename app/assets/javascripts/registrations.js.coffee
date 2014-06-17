
class window.Registrations
  constructor: (@container) ->
    @customFields = @container.find('.custom-account-fields')
    @useOAuthField = @container.find('input[name="user[use_google_oauth_registration]"]')

  handleState: () ->
    @state = if @useOAuthField.is(':checked') then 'oauth' else 'password'
    if @state == 'oauth'
      @customFields.hide()
    else
      @customFields.show()

  onDocLoad: () ->
    @useOAuthField.bind('change', (e) => @handleState())
    @handleState()
