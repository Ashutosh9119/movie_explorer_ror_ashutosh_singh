class UpdateSubscriptionsForNewValidityStructure < ActiveRecord::Migration[7.1]
  def up
    add_column :subscriptions, :validity, :string, null: false, default: "monthly"
    add_column :subscriptions, :start_date, :datetime
    add_column :subscriptions, :end_date, :datetime
    add_column :subscriptions, :amount, :decimal, precision: 10, scale: 2

    execute <<-SQL
      UPDATE subscriptions
      SET validity = 'monthly',
          start_date = created_at,
          end_date = created_at + INTERVAL '30 days',
          amount = CASE
            WHEN plan_type = 0 THEN 499.00
            WHEN plan_type = 1 THEN 999.00
            ELSE 499.00
          END
    SQL

    remove_column :subscriptions, :plan_type
  end

  def down
    add_column :subscriptions, :plan_type, :integer, null: false, default: 0

    execute <<-SQL
      UPDATE subscriptions
      SET plan_type = CASE
        WHEN validity = 'daily' THEN 0
        WHEN validity = 'weekly' THEN 0
        WHEN validity = 'monthly' THEN 1
        ELSE 0
      END
    SQL

    remove_column :subscriptions, :validity
    remove_column :subscriptions, :start_date
    remove_column :subscriptions, :end_date
    remove_column :subscriptions, :amount
  end
end