class Project

  attr_accessor :desc, :tech

  def self.all
    @all ||= [
              {
                :title => "SnapKnot.com",
                :image => '1.jpg',
                :desc => "SnapKnot.com is a directory of thousands of wedding photographers. Wedding Photographers can signup and create portfolios that showcase their work. Brides can search for photographers by city and price range. My job was to optimize database performance, to integrate with 3rd party payment gateways and photohosting sites, to implement a web service for the iPhone app, and to get geospatial searches to work with latitude and longtitude coordinates.",
                :tech => 'Ruby on Rails, jQuery, Amazon S3, MySQL, Ubuntu Linux, Linode'
              },

              {
                :title => "MyLearningPlan.com",
                :image => '2.jpg',
                :desc => 'My Learning Plan is a massive form automation app. It serves millions of school districts in the United States. Most K-12 teachers need to do professional development for a variety of reasons - salary increases or legal requirements - and this app tracks their progress for their school districts. My job has been to port tens of thousands of lines of classic ASP to C# on the Microsoft .NET 4.0 framework.',
                :tech => 'Microsoft .NET, IIS, Classic ASP and ASP.NET, COM+, MVC3, ExtJS'
              }
             ]
  end


end
