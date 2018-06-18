require_relative '../../environment.rb'

class CreateCircuitsTable < ActiveRecord::Migration[4.2]

  def up
    create_table :circuits do |t|
      t.string :name, null: false
      t.string :long_name
      t.string :country
      t.timestamps
    end

    add_index :circuits, :name, unique: true
    puts 'ran up method'
  end 

  def down
    drop_table :circuits
    puts 'ran down method'
  end

end

CreateCircuitsTable.migrate(ARGV[0] || :up)
