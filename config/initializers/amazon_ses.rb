ActionMailer::Base.add_delivery_method :ses, AWS::SES::Base, {
  access_key_id: AppConfiguration.get('AMAZON_ACCESS_KEY_ID'),
  secret_access_key: AppConfiguration.get('AMAZON_SECRET_ACCESS_KEY'),
  server: 'email.us-west-2.amazonaws.com'
}


