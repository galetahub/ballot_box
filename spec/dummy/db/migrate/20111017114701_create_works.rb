class CreateWorks < ActiveRecord::Migration
  def self.up
    create_table :works do |t|
      t.string :title
      t.integer :position
      t.integer :rating
      t.integer :group_id
      t.timestamps
    end
  end

  def self.down
    drop_table :works
  end
end
