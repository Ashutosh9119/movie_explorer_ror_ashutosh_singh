Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins [
      'http://localhost:3000', # Local frontend development
      'https://movie-explorer-frontend.onrender.com' # Replace with your actual frontend production URL
    ]
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true
  end
end