# app/admin/subscription.rb
ActiveAdmin.register Subscription do
  permit_params :user_id, :plan_type, :status, :stripe_customer_id, :stripe_subscription_id, :expires_at

  # Index view
  index do
    selectable_column
    id_column
    column :user
    column :plan_type
    column :status
    column :stripe_customer_id
    column :stripe_subscription_id
    column :expires_at
    column :created_at
    column :updated_at
    actions
  end

  # Filters
  filter :user, as: :select, collection: -> { User.pluck(:email, :id) }
  filter :plan_type, as: :select, collection: Subscription::PLAN_TYPES
  filter :status, as: :select, collection: Subscription::STATUSES
  filter :expires_at
  filter :created_at
  filter :updated_at

  # Show view
  show do
    attributes_table do
      row :id
      row :user
      row :plan_type
      row :status
      row :stripe_customer_id
      row :stripe_subscription_id
      row :expires_at
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end

  # Form for creating/editing
  form do |f|
    f.inputs do
      f.input :user, as: :select, collection: User.pluck(:email, :id)
      f.input :plan_type, as: :select, collection: Subscription::PLAN_TYPES
      f.input :status, as: :select, collection: Subscription::STATUSES
      f.input :stripe_customer_id
      f.input :stripe_subscription_id
      f.input :expires_at, as: :datetime_picker
    end
    f.actions
  end

  # Controller customizations
  controller do
    def scoped_collection
      resource_class.includes(:user)
    end
  end
end