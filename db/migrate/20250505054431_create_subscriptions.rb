class CreateSubscriptions < ActiveRecord::Migration[7.0]
  def change
    create_table :subscriptions, if_not_exists: true do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :plan_type, null: false
      t.string :status, null: false
      t.timestamps
    end

    if index_exists?(:subscriptions, :user_id, name: "index_subscriptions_on_user_id") && !index_exists?(:subscriptions, :user_id, unique: true, name: "index_subscriptions_on_user_id")
      remove_index :subscriptions, column: :user_id, name: "index_subscriptions_on_user_id"
    end

    unless index_exists?(:subscriptions, :user_id, unique: true, name: "index_subscriptions_on_user_id")
      add_index :subscriptions, :user_id, unique: true
    end
  end
end