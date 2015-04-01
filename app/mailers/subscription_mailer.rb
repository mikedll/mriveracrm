class SubscriptionMailer < ActionMailer::Base

  add_template_helper(MailerHelper)
  default from: "MRivera CRM Admin <#{MikedllCrm::Configuration.get('DEFAULT_EMAIL_SENDER')}>"

  def status_inactive(us)
    @us = us
    mail :to => us.business.an_owner.email, :subject => I18n.t('usage_subscriptions.trial_expired')
  end

  def welcome(us)
    @us = us
    mail :to => us.business.an_owner.email, :subject => I18n.t('usage_subscriptions.welcome', :title => @us.business.default_mfe.title)
  end

end

