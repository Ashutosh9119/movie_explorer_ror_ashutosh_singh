class ReplacePlanWithIsPremiumInMovies < ActiveRecord::Migration[7.1]
  def up
    add_column :movies, :is_premium, :boolean, default: false, null: false

    execute <<-SQL
      UPDATE movies
      SET is_premium = CASE
        WHEN plan = 1 THEN true
        ELSE false
      END
    SQL

    remove_column :movies, :plan
  end

  def down
    add_column :movies, :plan, :integer, default: 0, null: false

    execute <<-SQL
      UPDATE movies
      SET plan = CASE
        WHEN is_premium = true THEN 1
        ELSE 0
      END
    SQL

    remove_column :movies, :is_premium
  end
end