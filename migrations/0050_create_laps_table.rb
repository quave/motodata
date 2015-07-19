require_relative '../environment.rb'

class CreateLapsTable < ActiveRecord::Migration

  def up
    create_table :laps do |t|
      t.integer :sequence, null: false
      t.integer :position, null: false, default: 0
      t.integer :time
      t.integer :t1
      t.integer :t2
      t.integer :t3
      t.integer :t4
      t.float :speed
      t.boolean :finished
      t.boolean :pit
      t.string :session, null: false
      t.timestamps
    end

    add_reference :laps, :rider, index: true, foreign_key: true
    add_reference :laps, :event, index: true, foreign_key: true
    add_index :laps, [:event_id, :rider_id, :session]
    puts 'ran up method'
  end 

  def down
    drop_table :laps
    puts 'ran down method'
  end

end

CreateLapsTable.migrate(ARGV[0] || :up)