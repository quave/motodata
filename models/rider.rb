class Rider
    include Mongoid::Document

    field :number, type: Integer
    field :team, type: String
    embedded_in :person

    validates :number, presence: true
    validates :team, presence: true
end
