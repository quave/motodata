class Person < ActiveRecord::Base
    has_many :riders

    validates :first_name, presence: true
    validates :last_name, presence: true
end