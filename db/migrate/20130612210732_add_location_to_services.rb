class AddLocationToServices < ActiveRecord::Migration
  def change
    add_column :services, :ulocation, :string
  end
end
