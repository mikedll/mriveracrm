class TodayController < ApplicationController
  layout 'minimal'
  
  def show
    a = YAML.load <<-TASKS
  10 Regular: 
    - 7 Hours Sleep

    - 1 maint, clean, shower, shopping

    - 1 fitness & presentation, drawing (weights)

    - 1 fitness & presentation, drawing (cardio)

  10 Rotating work:

    - 4 service for plovertech

    - 5 service for jamie and spencer

  4 Rotating other

    - 2 quagress|bustadonkey|pimpeq|pybomber service

    - 1 (Science & Medicine, Math, Stats and Engineering) bio exercise

    - 0.5 publish something.

    - 1 play with new tech (node.js, and publish)

    - 1 hr math exercises, with some publishing.

    - 0.5 tutoring/stack overflow/math answering

    - 1 socialize / penpal / write

    - 1 dragon development (emacs, personal tool development,
      portfolio enhancements, daily budgeting and planning, automation
      of daily activities like mikedll/today, base, publishing
      platform development, quagress input)

    - 1 fitness & presentation, drawing (paper and photoshop)

    - 1 (Math, Stats and Engineering) physics exercise

    - 1 fitness & presentation, drawing (music production)

    - 1 fitness & presenttiation (voice)

    - 0.5 language learning; hindi

    - 0.5 stats exercises

    - 0.5 (stats & enginerring) physics exercises

    - 0.5 programming / algorithm competition

    - 0.5 internet reading
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
