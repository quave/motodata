require_relative '../environment.rb'

class CreateRidersTable < ActiveRecord::Migration

  def up
    add_column :riders, :category, :string
    puts 'ran up method'
  end 

  def down
    remove_column :riders, :category
    puts 'ran down method'
  end

end

CreateRidersTable.migrate(ARGV[0] || :up)