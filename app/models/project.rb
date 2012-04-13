class Project

  attr_accessor :desc, :tech

  def self.all
    @all ||= [
              {
                :title => "SnapKnot.com",
                :image => '1.jpg',
                :desc => "SnapKnot.com is a directory of wedding photographers. Photographers can create profiles and portfolios that demonstrate their work. Brides and other leads can search for photographers by city and price range. My role was to optimize database performance, implement a web service for the iPhone app to talk to, and to get spatial searches to work with latitude and longtitude coordinates. Mike and Reid, the site's cofounders, were great guys to work with.",
                :tech => 'Ruby on Rails, Amazon S3, MySQL, Ubuntu Linux, Linode'
              },
              {
                :title => "MyLearningPlan.com",
                :image => '2.jpg',
                :desc => 'My Learning Plan is a massive data processing automation app. It serves millions of school districts in the United States. Most K-12 teachers need to do professional development for a variety of reasons - salary increases or state legal requirements - and this app tracks that information in a centralized fashion for school districts. My job has been to port a ton of legacy classic ASP code to the Microsoft .NET 4.0 framework, which including a lot of interopability work.',
                :tech => 'Microsoft .NET, IIS, Classic ASP and ASP.NET, COM+, MVC3, ExtJS'
              }
             ]
  end


end
