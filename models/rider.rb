class Rider < ActiveRecord::Base
    belongs_to :person

    validates :number, presence: true
    validates :team, presence: true
end