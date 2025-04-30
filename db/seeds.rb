AdminUser.create!(email: 'admin@gmail.com', password: 'Password', password_confirmation: 'Password') if Rails.env.development?
