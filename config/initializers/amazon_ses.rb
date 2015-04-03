ActionMailer::Base.add_delivery_method :ses, AWS::SES::Base, {
  access_key_id: MikedllCrm::Configuration.get('AMAZON_ACCESS_KEY_ID'),
  secret_access_key: MikedllCrm::Configuration.get('AMAZON_SECRET_ACCESS_KEY'),
  server: 'email.us-west-2.amazonaws.com'
}


