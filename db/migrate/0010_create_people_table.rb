require_relative '../../environment.rb'

class CreatePeopleTable < ActiveRecord::Migration[4.2]

  def up
    create_table :people do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :country
      t.string :birthplace
      t.string :info
      t.timestamps
    end

    add_index :people, [:first_name, :last_name], unique: true
    puts 'ran up method'
  end 

  def down
    drop_table :people
    puts 'ran down method'
  end

end

CreatePeopleTable.migrate(ARGV[0] || :up)
