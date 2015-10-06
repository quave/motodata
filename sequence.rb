class Sequence
    def initialize(debug = true)
        @debug = debug
        @steps = []
    end

    def add(name, &block)
        @steps << [name, block]
    end

    def run(data, start_index=0, context=nil)
        process(data, context, @steps[start_index..-1]) 
    end

    private
    def process(data, context, steps)
        step = steps.shift

        puts "Start step #{step[0]} with #{data.inspect} and #{context.inspect}" if @debug

        begin
            return step[1].call data, context do |data, context|
                ok = process(data, context, steps.clone)
            end
        #rescue => e
            #puts e
            #return false
        end
    end
end
