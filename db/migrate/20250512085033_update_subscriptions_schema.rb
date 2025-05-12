class UpdateSubscriptionsSchema < ActiveRecord::Migration[7.1]
  def up
    # Add new columns
    add_column :subscriptions, :plan_type, :string, null: false
    add_column :subscriptions, :stripe_customer_id, :string
    add_column :subscriptions, :stripe_subscription_id, :string
    add_column :subscriptions, :expires_at, :datetime

    # Copy data from old columns to new columns
    Subscription.reset_column_information
    Subscription.find_each do |subscription|
      subscription.update!(
        plan_type: subscription.validity || 'monthly', # Copy validity to plan_type, default to 'monthly' if nil
        expires_at: subscription.end_date,            # Copy end_date to expires_at
        stripe_customer_id: subscription.user&.stripe_customer_id # Copy from user if available
      )
    end

    # Set default for status
    change_column :subscriptions, :status, :string, default: "active", null: false

    # Remove old columns
    remove_column :subscriptions, :validity
    remove_column :subscriptions, :start_date
    remove_column :subscriptions, :end_date
    remove_column :subscriptions, :amount
    remove_column :subscriptions, :session_id
    remove_column :subscriptions, :session_expires_at

    # Update indexes
    remove_index :subscriptions, name: "index_subscriptions_on_user_id" # Remove the unique index
    add_index :subscriptions, :user_id # Add a non-unique index
    add_index :subscriptions, :expires_at, name: "index_subscriptions_on_expires_at"
  end

  def down
    # Reverse the changes for rollback
    add_column :subscriptions, :validity, :string, default: "monthly", null: false
    add_column :subscriptions, :start_date, :datetime
    add_column :subscriptions, :end_date, :datetime
    add_column :subscriptions, :amount, :decimal, precision: 10, scale: 2
    add_column :subscriptions, :session_id, :string
    add_column :subscriptions, :session_expires_at, :datetime

    # Copy data back
    Subscription.reset_column_information
    Subscription.find_each do |subscription|
      subscription.update!(
        validity: subscription.plan_type || 'monthly',
        end_date: subscription.expires_at
        # Note: We can't restore stripe_customer_id to user, and other fields are lost
      )
    end

    # Revert status default
    change_column :subscriptions, :status, :string, default: nil, null: false

    # Revert indexes
    remove_index :subscriptions, :user_id
    remove_index :subscriptions, name: "index_subscriptions_on_expires_at"
    add_index :subscriptions, :user_id, unique: true, name: "index_subscriptions_on_user_id"

    # Remove new columns
    remove_column :subscriptions, :plan_type
    remove_column :subscriptions, :stripe_customer_id
    remove_column :subscriptions, :stripe_subscription_id
    remove_column :subscriptions, :expires_at
  end
end