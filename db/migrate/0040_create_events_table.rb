require_relative '../../environment.rb'

class CreateEventsTable < ActiveRecord::Migration[4.2]

  def up
    create_table :events do |t|
      t.integer :year, null: false
      t.integer :number, null: false
      t.timestamps
    end

    add_reference :events, :circuit, index: true, foreign_key: true
    add_index :events, :year
    puts 'ran up method'
  end 

  def down
    drop_table :events
    puts 'ran down method'
  end

end

CreateEventsTable.migrate(ARGV[0] || :up)
