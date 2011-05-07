class FalconCreateEncodings < ActiveRecord::Migration
  def self.up
    create_table :falcon_encodings do |t|
      t.string   :profile_name, :limit => 50, :null => false
      t.string   :source_path, :null => false
      
      t.string   :videoable_type, :limit => 50
      t.integer  :videoable_id
      
      t.integer  :status, :default => 0
      t.integer  :progress
      t.integer  :width
      t.integer  :height
      
      t.integer  :encoding_time
      t.datetime :encoded_at
		  
      t.timestamps
    end

    add_index :falcon_encodings, [:videoable_type, :videoable_id]
    add_index :falcon_encodings, :status
  end

  def self.down
    drop_table :falcon_encodings
  end
end
