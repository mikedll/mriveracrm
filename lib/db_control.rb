class DbControl
  class << self
    def with_output(present_participle)
      puts "#{present_participle}."
      yield
      puts "...done #{present_participle.downcase}."
    end

    def email_mutate(e, i)
       "#{e.gsub('@', '.')}#{i}@michaelrivera.com"
    end

  end
end
