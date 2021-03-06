

#
# Binding to the document's keyup is no handled here.
#
class window.Hotkeys

  constructor: () ->
    @hotKeyRegistry = {}

  handleKeyUp: (e) ->
    for k, el of @hotKeyRegistry
      if(k == String.fromCharCode(e.keyCode).toLowerCase())
        e.stopPropagation()
        if (typeof(el.data('events')) != "undefined") || typeof($._data( el, "events" )) != 'undefined' || typeof(el.prop('href')) == 'undefined' || el.prop('href') == '#'
          el.trigger('click') if !el.hasClass('disabled')
        else
          window.location = el.attr('href');

  onDocLoad: () ->
    @hotKeyRegistry = {}
    $('a:visible, button:visible').each((i, el) =>
      k = $(el).data('hotkey')
      if(typeof(k) != "undefined")
        @hotKeyRegistry[k] = $(el)
        if $(el).is('a') && $(el).find('span.hotkey').length == 0
          text = $(el).text()
          for c, j in text
            if(c.toLowerCase() == k.toLowerCase())
              $(el).html( text.substr(0, j-1) + '<span class="hotkey">' + c + '</span>' + text.substr(j + 1, text.length - j) )
              break
    )
    this

$(() -> $('body').data('hotkeys', (new Hotkeys()).onDocLoad()));
