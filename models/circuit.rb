class Circuit
    include Mongoid::Document
    
    field :name, type: String
    field :long_name, type: String
    field :country, type: String

    validates :name, presence: true
    validates :name, uniqueness: true

    index({name: 1}, {unique: true})
end
