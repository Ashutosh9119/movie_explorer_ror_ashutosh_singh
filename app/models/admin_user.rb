# app/models/admin_user.rb
class AdminUser < ApplicationRecord
  # Include default Devise modules for ActiveAdmin
  devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable

  # Validations (optional, depending on your requirements)
  validates :email, presence: true, uniqueness: true
  validates :password, presence: true, length: { minimum: 6 }, if: :password_required?

  private

  # Helper method to check if password validation is required
  def password_required?
    !persisted? || !password.nil? || !password_confirmation.nil?
  end
end