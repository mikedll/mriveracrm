class TodayController < ApplicationController
  layout 'home'
  
  def show

    a = YAML.load <<-TASKS
    - 8 Hours Sleep
    - 1 hr getdonkies.com
    - 1 quagress
    - 1 Bomberman/altitude project
    - 1 Nochipmonks
    - 1 hr PimpEQ
    - 1 fitness & presentation, drawing (paper and photoshop)
    - 3 hr math exercises, with some publishing.
    - 1 dragon development (emacs, personal tool development, portfolio enhancements, daily budgeting and planning, automation of daily activities like mikedll/today, base, publishing platform development, quagress input)
    - 1 eating / shopping
    - 5 apply/advertise for a job/room. make a letter. write. publish something. 
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
