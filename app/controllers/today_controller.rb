class TodayController < ApplicationController
  layout 'home'
  
  def show
    a = YAML.load <<-TASKS
      - 3 math/stats/algorithm training
      - 2 bio/physics training
      - 1 fitness & presentation
      - 2 dragon development (including quagress input and development)
      - 3 service 1
      - 3 service 2
      - 1 hr breakfast / cleaning clothes / shower
      - 0.5 shopping (food, other)
      - 0.5 hour internet reading
      - 0.5 write to mel/amy/peter/andrew, or apply for a job somewhere
      - 0.5 blog writing & publishing
    TASKS
    @tasks = randtasks(a)
    @old_tasks = randtasks(a, Time.zone.now - 1.day)
  end

  def randtasks(a,t = Time.zone.now)
    random_indicies(a.size, t).map { |i| a[i] }
  end

  def random_indicies(n, t)
    a = []
    srand( t.day * 100 + t.mon * 1000 )
    100.times { a << ((rand() * 100).to_i % n) }    
    a.uniq
  end
end
