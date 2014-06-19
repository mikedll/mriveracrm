
task :mystats do
  c = 'find app/assets/javascripts -iname "*.coffee" -or -iname "*.js" -not -iname "*jquery*" -not -iname "*underscore*" -not -iname "*bootstrap*" -not -ipath "*vendor*" -not -iname "*gmailr*" -not -iname "*sh*"  | xargs wc -l'
  puts `#{c}`

  c = 'find app -iname "*.rb" | xargs wc -l'
  puts `#{c}`
end
