
#
# Binding to the document's keyup is no handled here.
#
# Branched from original hot keys which was causing too much trouble with window.location=
#
class EventHotKeys

  constructor: () ->
    @hotKeyRegistry = {}

  handleKeyUp: (e) ->
    for k, el of @hotKeyRegistry
      if(k == String.fromCharCode(e.keyCode).toLowerCase())
        e.stopPropagation()
        $(el).trigger('click') if !$(el).hasClass('disabled')

  bind: (container) ->
    @hotKeyRegistry = {}
    container.find('a:visible, button:visible').each((i, el) =>
      k = $(el).data('hotkey')
      if(typeof(k) != "undefined")
        @hotKeyRegistry[k] = $(el)
        # this breaks the bootstrap icons
        # if $(el).is('a') && $(el).find('span.hotkey').length == 0
        #   text = $(el).text()
        #   for c, j in text
        #     if(c.toLowerCase() == k.toLowerCase())
        #       $(el).html( text.substr(0, j) + '<span class="hotkey">' + c + '</span>' + text.substr(j + 1, text.length - j) )
        #       break
    )
    this
