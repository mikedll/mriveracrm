
class Main

  constructor: () ->
    @current = 0
    @choices = ['anza1.png', 'beach3.jpg', 'forrest.png', 'beachwithsunfire.png', 'glowingranch.png', ]
    @interval = 6000
    @fadeOut = 1000

  onDocLoad: () ->
    @current = Math.round(Math.random() * (@choices.length - 1))
    $('#header').css('background', "top center url(/images/#{@choices[ @current ]}) no-repeat")

    rotateImages = () =>
      $('#header').fadeOut(@fadeOut, () =>
        @next = @current
        while @next == @current
          @next = Math.round(Math.random() * (@choices.length - 1))
        @current = @next

        host = $('#header').data('asset-host')
        host = "" if !host?
        $('#header').css('background', "top center url(#{host}/images/#{@choices[ @current ]}) no-repeat")
        $('#header').fadeIn(@fadeOut, () =>
          setTimeout(rotateImages, @interval)
        )
      )

    setTimeout(rotateImages, @interval)
    this

$(() ->
  $('body').data('main', (new Main()).onDocLoad())
  )
