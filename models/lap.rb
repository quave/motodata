class Lap
    include Mongoid::Document

    field :sequence, type: Integer
    field :position, type: Integer
    field :time, type: Integer
    field :t1, type: Integer
    field :t2, type: Integer
    field :t3, type: Integer
    field :t4, type: Integer
    field :speed, type: Float
    field :finished, type: Boolean
    field :pit, type: Boolean

    #session
    belongs_to :rider
    belongs_to :event
end
