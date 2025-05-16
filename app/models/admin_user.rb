class AdminUser < ApplicationRecord
  # Devise modules (ensure :trackable is included if using current_sign_in_at etc.)
  devise :database_authenticatable, :recoverable, :rememberable,
         :validatable, :trackable

  # Required by ActiveAdmin (Ransack) to avoid 500 errors on filters
  def self.ransackable_attributes(auth_object = nil)
    %w[id email current_sign_in_at sign_in_count created_at]
  end

  # Optional: if your AdminUser has any associations, whitelist them here
  def self.ransackable_associations(auth_object = nil)
    []
  end
end
