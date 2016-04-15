class Person
    include Mongoid::Document
    include ActiveModel::Validations

    field :first_name, type: String
    field :last_name, type: String
    field :birthplace, type: String
    field :country, type: String
    field :info, type: String
    embeds_many :riders

    validates :first_name, presence: true
    validates :last_name, presence: true

    index({first_name: 1, last_name: 1}, {unique: true})
end

