require_relative '../environment.rb'

class CreateRidersTable < ActiveRecord::Migration

  def up
    create_table :riders do |t|
      t.integer :number, null: false
      t.string :team, null: false
      t.timestamps
    end

    add_reference :riders, :person, index: true
    puts 'ran up method'
  end 

  def down
    drop_table :riders
    puts 'ran down method'
  end

end

CreateRidersTable.migrate(ARGV[0] || :up)