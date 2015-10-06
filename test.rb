require 'parallel'

def main
    
    10.times do 
        Parallel.each(['a','b','c'], :in_processes=>3) do |one_letter| 
            puts one_letter
            sleep 1
        end
        
    end
end

main