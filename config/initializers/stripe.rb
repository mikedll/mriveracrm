
require "stripe"

Stripe.api_key = MikedllCrm::Credentials.get('stripe.secret_key')
STRIPE_PUBLISHABLE_KEY = MikedllCrm::Credentials.get('stripe.publishable_key')

