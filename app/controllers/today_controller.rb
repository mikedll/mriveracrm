class TodayController < ApplicationController
  layout 'home'
  
  def show
    a = YAML.load <<-TASKS
    - 7 Hours Sleep
    - 5 bcg service
    - 1 dragon development (emacs, personal tool development, portfolio enhancements, daily budgeting and planning, automation of daily activities like mikedll/today, base, publishing platform development, quagress input)
    - 1 quagress service
    - 3 hr math exercises, with some publishing.
    - 2 hr math tool development
    - 0.5 more of fitness & presentation, drawing (paper and photoshop)
    - 1.25 going out to eat
    - 1 cooking, cleaning
    - 1.25 transportation
    - 1 apply for a job. make a letter. write. publish something. 
    TASKS
    @tasks = randtasks(a)
    @total = total( randtasks(a) )
    @old_tasks = randtasks(a, Time.zone.now - 1.day)
  end

  def total( tasks )
    tasks.inject(0) { |acc,t| t =~ /^(\d(\.\d+)?)/; acc += $1.to_f }
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
