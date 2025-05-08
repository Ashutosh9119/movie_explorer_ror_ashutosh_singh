class Subscription < ApplicationRecord
  # Associations
  belongs_to :user

  # Validations
  validates :plan_type, presence: true
  validates :status, presence: true, inclusion: { in: %w[active inactive] }

  # Enums
  enum plan_type: { basic: 0, premium: 1 }
  enum status: { active: 'active', inactive: 'inactive' }

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "plan_type", "status", "updated_at", "user_id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["user"]
  end
end