

$(() ->
  reg = $('.new-registration-form')
  if reg.length > 0
    new Registrations(reg.first()).onDocLoad()

)