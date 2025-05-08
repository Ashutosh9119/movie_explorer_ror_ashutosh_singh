class CreateSubscriptions < ActiveRecord::Migration[7.0]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :plan_type, null: false
      t.string :status, null: false
      t.timestamps
    end

    add_index :subscriptions, :user_id, unique: true
  end
end