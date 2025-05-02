
Devise.setup do |config|
  config.jwt do |jwt|
    jwt.secret = ENV['SECRET_KEY_BASE'] || Rails.application.credentials.secret_key_base
    jwt.dispatch_requests = [
      ['POST', %r{^/users/sign_in$}],
      ['POST', %r{^/users$}]
    ]
    jwt.revocation_requests = [
      ['DELETE', %r{^/users/sign_out$}]
    ]
    jwt.expiration_time = 1.hour.to_i # Tokens expire after 1 hour
  end
end