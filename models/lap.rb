class Lap < ActiveRecord::Base
    belongs_to :rider
    belongs_to :event
end