
class window.UrlManager
  constructor: () ->

  url: (suffix) ->
    prefix = $('meta[name=app-path-prefix]').attr('content')
    if prefix.length > 1 # '/' doesnt count
      prefix + suffix
    else
      suffix

$(() ->
  if not ('gUrlManager' of window)
    window.gUrlManager = new UrlManager()
  )

