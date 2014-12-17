class SubscriptionMailer < ActionMailer::Base

  default from: "MRivera CRM Admin <#{MikedllCrm::Configuration.get('DEFAULT_EMAIL_SENDER')}>"

  def status_inactive(us)
    @us = us
    mail :to => us.business.an_owner.email, :subject => I18n.t('usage_subscriptions.trial_expired')
  end

end

