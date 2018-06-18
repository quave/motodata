require_relative '../../environment.rb'

class AddCategoryToRidersTable < ActiveRecord::Migration[4.2]

  def up
    add_column :riders, :category, :string
    puts 'ran up method'
  end 

  def down
    remove_column :riders, :category
    puts 'ran down method'
  end

end

AddCategoryToRidersTable.migrate(ARGV[0] || :up)
