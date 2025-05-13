class UpdateSubscriptionsSchema < ActiveRecord::Migration[7.1]
  def up
    # Add new columns (skip plan_type since it already exists)
    add_column :subscriptions, :stripe_customer_id, :string unless column_exists?(:subscriptions, :stripe_customer_id)
    add_column :subscriptions, :stripe_subscription_id, :string unless column_exists?(:subscriptions, :stripe_subscription_id)
    add_column :subscriptions, :expires_at, :datetime unless column_exists?(:subscriptions, :expires_at)

    # Set default for status
    change_column :subscriptions, :status, :string, default: "active", null: false

    # Remove old columns (if they exist)
    remove_column :subscriptions, :validity if column_exists?(:subscriptions, :validity)
    remove_column :subscriptions, :start_date if column_exists?(:subscriptions, :start_date)
    remove_column :subscriptions, :end_date if column_exists?(:subscriptions, :end_date)
    remove_column :subscriptions, :amount if column_exists?(:subscriptions, :amount)
    remove_column :subscriptions, :session_id if column_exists?(:subscriptions, :session_id)
    remove_column :subscriptions, :session_expires_at if column_exists?(:subscriptions, :session_expires_at)

    # Update indexes
    remove_index :subscriptions, name: "index_subscriptions_on_user_id" if index_exists?(:subscriptions, :user_id)
    add_index :subscriptions, :user_id # Non-unique index
    add_index :subscriptions, :expires_at, name: "index_subscriptions_on_expires_at" unless index_exists?(:subscriptions, :expires_at)
  end

  def down
    # Reverse the changes for rollback
    add_column :subscriptions, :validity, :string, default: "monthly", null: false unless column_exists?(:subscriptions, :validity)
    add_column :subscriptions, :start_date, :datetime unless column_exists?(:subscriptions, :start_date)
    add_column :subscriptions, :end_date, :datetime unless column_exists?(:subscriptions, :end_date)
    add_column :subscriptions, :amount, :decimal, precision: 10, scale: 2 unless column_exists?(:subscriptions, :amount)
    add_column :subscriptions, :session_id, :string unless column_exists?(:subscriptions, :session_id)
    add_column :subscriptions, :session_expires_at, :datetime unless column_exists?(:subscriptions, :session_expires_at)

    # Revert status default
    change_column :subscriptions, :status, :string, default: nil, null: false

    # Revert indexes
    remove_index :subscriptions, :user_id if index_exists?(:subscriptions, :user_id)
    remove_index :subscriptions, name: "index_subscriptions_on_expires_at" if index_exists?(:subscriptions, :expires_at)
    add_index :subscriptions, :user_id, unique: true, name: "index_subscriptions_on_user_id" unless index_exists?(:subscriptions, :user_id)
  end
end