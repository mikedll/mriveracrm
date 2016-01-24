class AlertMailer < ActionMailer::Base

  default from: "M. Rivera CRM Admin <#{AppConfiguration.get('DEFAULT_EMAIL_SENDER')}>"

  def computer_down(business, monitored_computer)
    @business = business
    @monitored_computer = monitored_computer
    mail :to => @business.an_owner.email, :subject => I18n.t('monitored_computer.computer_down', :hostname => monitored_computer.hostname)
  end

end
