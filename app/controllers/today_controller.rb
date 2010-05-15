class TodayController < ApplicationController
  layout 'home'
  
  def show
    b = YAML.load <<-TASKS
      - 3 math/stats/algorithm training
      - 2 bio/physics training
      - 1 fitness & presentation
      - 2 dragon development (including quagress input and development)
      - 3 service 1
      - 3 service 2
      - 1 hr breakfast / cleaning clothes / shower
      - .5 shopping (food, other)
      - .5 hour internet reading
      - .5 write to mel/amy/peter, or apply for a job somewhere
      - .5 blog writing & publishing
    TASKS
    
    @tasks = random_indicies.map { |i| b[i] }
    @old_tasks = random_indicies(Time.zone.now - 1.day).map { |i| b[i] }
  end


  def random_indicies(t = Time.zone.now)
    a = []
    srand( t.day * 100 + t.mon * 1000 )
    100.times { a << ((rand() * 100).to_i % 6) }    
    a.uniq
  end
end
