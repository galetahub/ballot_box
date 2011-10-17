class BallotBoxCreateVotes < ActiveRecord::Migration
  def self.up
    create_table :ballot_box_votes do |t|
      # Voter
      t.string  :voter_type, :limit => 40
      t.integer :voter_id
      
      # Voteable
      t.string  :voteable_type, :limit => 40
      t.integer :voteable_id
      
      # User info
      t.integer :ip_address, :limit => 8
      t.string  :user_agent
      t.string  :referrer
      t.string  :browser_name, :limit => 40
      t.string  :browser_version, :limit => 15
      t.string  :browser_platform, :limit => 15

      # Vote value
      t.integer :value, :default => 1
		  
      t.timestamps
    end

    add_index :ballot_box_votes, [:voter_type, :voter_id]
    add_index :ballot_box_votes, [:voteable_type, :voteable_id]
    add_index :ballot_box_votes, :ip_address
  end

  def self.down
    drop_table :ballot_box_votes
  end
end
