
#
# If we can do this from hotkeys then we don't need this.
#
$(() ->
  $(document).bind('keyup', (e) ->
    $('body').data('hotkeys').handleKeyUp(e)
  ))
