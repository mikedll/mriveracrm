
FactoryGirl.reload

DatabaseCleaner.clean_with(:truncation)

mfe = FactoryGirl.create(:marketing_front_end,
                         :host => "devmarketing.mriveracrm.com",
                         :title => "Development M. Rivera CRM",
                         :google_oauth2_client_id => AppConfiguration.get('google.oauth2_client_id'),
                         :google_oauth2_client_secret => AppConfiguration.get('google.oauth2_client_secret'))

b = FactoryGirl.create(:business,
                       :owner_email => AppConfiguration.get('safe_admin_email'),
                       :host => "dev1.michaelriveraco.com",
                       :default_mfe => mfe,
                       :google_oauth2_client_id => AppConfiguration.get('dev_owned_google.oauth2_client_id'),
                       :google_oauth2_client_secret => AppConfiguration.get('dev_owned_google.oauth2_client_secret'))


