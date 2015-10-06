require_relative 'sequence'

seq = Sequence.new

seq.add :parse_dir do |data, &block|
    res = [1,2,3,4,5,6]
    res.each{|r| block.call(r, {c: 345}) }
end

seq.add :parse_file do |data, context, &block|
    res = [
        {a: 3, b: 6},
        {a: 4, b: 5},
        {a: 7, b: 8},
        {a: 1, b: 0},
    ]

    res.each{|r| block.call(r, context) }
end

seq.add :parse_rider do |data, context|
end

seq.run 'asdf'