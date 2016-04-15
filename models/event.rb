class Event
    include Mongoid::Document

    field :year, type: Integer
    field :number, type: Integer
    
    validates :year, presence: true
    validates :number, presence: true

    embeds_many :laps
end
