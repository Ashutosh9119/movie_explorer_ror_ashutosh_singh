class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable,
         :validatable, :jwt_authenticatable, jwt_revocation_strategy: self

  # Associations
  has_one :subscription, dependent: :destroy
  has_one_attached :profile_picture
  after_create :create_default_subscription
  enum role: { user: 0, supervisor: 1 }

  validates :name, presence: true, length: { maximum: 100, minimum: 3 }
  validates :mobile_number, presence: true, format: { with: /\A(\+?[1-9]\d{0,3})?\d{9,14}\z/ }, uniqueness: true
  validates :email, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :profile_picture, content_type: ['image/png', 'image/jpeg'], allow_blank: true

  scope :by_role, ->(role) { where(role: role) }
  scope :recent, -> { order(created_at: :desc) }

  def jwt_payload
    { 'role' => role }
  end

  def on_jwt_dispatch(token, payload)
    self.jti = payload['jti']
    save!
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "email", "id", "name", "mobile_number", "role", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["subscription"]
  end

  def profile_picture_url
    if profile_picture.attached?
      profile_picture.blob.service_url
    else
      nil      
    end
  end

  def profile_picture_thumbnail
    if profile_picture.attached?
      Cloudinary::Utils.cloudinary_url(profile_picture.key, transformation: [
        { width: 100, height: 100, crop: "fill", gravity: "face" }
      ])
    else
      nil
    end
  end

  def create_default_subscription
    begin 
      customer = Stripe::Customer.create(email: email)
      Subscription.create!(user: self, plan_type: 'basic', status: 'active', stripe_customer_id: customer.id)
    rescue Stripe::StripeError
      Subscription.create!(user: self, plan_type: 'basic', status: 'active')
    end
  end
end