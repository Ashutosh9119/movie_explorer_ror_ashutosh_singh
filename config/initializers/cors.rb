Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins [
      'http://localhost:3000', # Local frontend development
      'https://movie-explorer-ror-ashutosh-singh.onrender.com' # Swagger UI and backend origin
    ]
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: false, # Disabled since JWT is used, no cookies needed
      expose: ['Authorization'] # Expose Authorization header for JWT
  end
end