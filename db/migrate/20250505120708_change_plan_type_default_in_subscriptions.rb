class ChangePlanTypeDefaultInSubscriptions < ActiveRecord::Migration[7.1]
  def change
    change_column_default :subscriptions, :plan_type, from: 1, to: 0
  end
end