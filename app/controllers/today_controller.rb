class TodayController < ApplicationController
  layout 'home'
  
  def show
    t = Time.zone.now
    srand( t.day * 100 + t.mon * 1000 )
    b = ["bio/physics", "math/stats/algorithm", "fitness & presentation", "dragon development", "service 1", "service 2"]
    a = []
    100.times { a << ((rand() * 100).to_i % 6) }
    @tasks = a.uniq.map { |i| b[i] }
  end

end
