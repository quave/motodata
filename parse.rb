require 'time'
require 'open-uri'
require 'yaml'
require_relative 'environment'
require 'pluck_to_hash'

$data_dir = 'data'
$log_ledders = false
$error_raw_riders = []

$circuits = Circuit.all.to_a
$people = Person.all.pluck_h(:id, :first_name, :last_name)


def extract_lines (file)
    pages = File.open(file).read.force_encoding('utf-8').split "\f"

    def process_raw_line(s)
        return '' if s.nil?

        striped = s.strip
        return '' if striped.empty?
        s.to_s.delete("\n")
    end

    lines = []

    pages.each do |page|
        skip = true
        half_2 = []

        page.lines.each do |l| 
            if l.include? 'Lap Time'
                skip = false
                next
            end

            if l.include? 'Fastest Lap'
                skip = true
            end

            next if skip or l.length < 2

            l1 = process_raw_line(l[0..96])
            l2 = process_raw_line(l[97..-1])
            lines << l1 unless l1 == ''
            half_2 << l2 unless l2 == ''
            
        end
        lines += half_2

    end

    lines
end

def detect_ladder(lines)
    min_ladder_length = 4
    min_elements = 4
    start = 0

    lines.each_with_index do |line, i|
        start = i
        # if more that min_elements in the line
        break if line.split(/\s+/).size < min_elements &&
            # and lines count more that i + min ladder length
            lines.size > i + min_ladder_length &&
            # and all lines of ladder have elements < min_elements
            (i+1..i+min_ladder_length).all? { |l| line.split(/\s+/).size < min_elements }
            #calculate ladder length
    end

    # no ladder detected
    return nil if start >= lines.size-1

    length = min_ladder_length
    #calculate length
    lines[start+min_ladder_length..-1].each do |line|
        length += 1 if line.split(/\s+/).size < min_elements
    end

    return [start, length]
end

def fix_ladder(lines, start, length)
    ladder = lines[start..start+length-1]

    res1 = ladder[0].strip
    res2 = ladder[1].strip

    ladder = ladder[2..-1]

    while ladder.size > 0
        line1 = ladder.find {|l| l[0..res1.length-1] =~ /\s+/ }
        if line1
            line1[0..res1.length-1] = res1
            res1 = line1
            ladder.delete(line1)
        end

        line2 = ladder.find {|l| l[0..res2.length-1] =~ /\s+/ }
        if line2
            line2[0..res2.length-1] = res2
            res2 = line2
            ladder.delete(line2)
        end
    end

    lines[start, 2] = [res1, res2]
    lines.slice!(start + 2, length - 2)

    lines
end

def split_riders(lines)
    rider_results = []

    rider = nil

    i = 0
    while i < lines.size
        line = lines[i]
        next_line = lines[i+1]
        res_regex = /^[0-9\s'.PIT\n\r\t]+$/
        unfinished_res_regex = /(cancelled)|(unfinished)/

        unless line =~ res_regex || line =~ unfinished_res_regex
            if rider
                rider_results << rider
            end
        
            rider = { res: [], head: [] }

            head_start = i
            lines[head_start..lines.size-1].each do |head_line|
                break if head_line =~ res_regex || head_line =~ unfinished_res_regex
                rider[:head] << head_line
                i += 1
            end

            next        
        end

        rider[:res] << line

        i += 1
    end 

    # fix res ladders
    rider_results.each do |rider|
        ladder_start, length = detect_ladder(rider[:res])

        next unless ladder_start
        if $log_ledders
            puts "ladder detected at #{ladder_start}, #{length}"
            puts rider[:res].to_yaml
            puts
        end
        rider[:res] = fix_ladder rider[:res], ladder_start, length

        if $log_ledders
            puts "ladder fixed as"
            puts rider[:res].to_yaml
            puts '------------------------------------------------------------------------------------'
        end
    end

    rider_results
end

def parse_rider(raw)
    def parse_time(str)
        match = /((\d)')?(\d{1,2})\.(\d{3})/.match(str)
        parsed = if match 
            match.captures
        else
            []
        end

        #Time.new 0, 1, 1, 0, parsed[-3].to_i, parsed[-2].to_i + Rational(parsed[-1].to_i, 10**3), '+00:00'
        parsed[-3].to_i * 60 * 1000 + parsed[-2].to_i * 1000 +parsed[-1].to_i
    end

    def parse_lap(line)
        pit = !!(line =~ /P/)
        line.gsub! /P/, ''

        if line =~ /unfinished|PIT/
            begin
                finished = false
                line.gsub!(/^(\s+)?(\d+)?(\s+)?unfinished|PIT/, '').strip!
                if speed_match = /\d{3}\.\d$/.match(line)
                    line.gsub!(/\d{3}\.\d$/, '').strip! 
                    speed = speed_match.captures[0]
                end
                t1, t2, t3, t4 = line.split(/\s+/).map(&:strip)
            rescue => e
                puts line
                puts e
                raise e
            end
        else
            finished = true
            _, lap, t1, t2, t3, t4, speed = line.strip.split(/\s+/).map(&:strip)
        end

        {
            lap: parse_time(lap), 
            t1: parse_time(t1),
            t2: parse_time(t2),
            t3: parse_time(t3),
            t4: parse_time(t4),
            speed: speed.to_f,
            pit: pit,
            finished: finished
        }
    end

    orig_head = raw[:head].map {|e| e.dup}
    rider = parse_head(raw[:head])
    puts orig_head.to_yaml unless rider
    puts unless rider

    return nil unless rider

    rider[:laps] = raw[:res].map { |line| parse_lap line }
    rider
end

def parse_head(head)
    number = nil
    head.each do |line|
        line.strip!
        line.gsub! /Full\s+laps=\d{1,2}/, ''
        line.gsub! /Total\s+laps=\d{1,2}/, ''
        line.gsub! /Runs=\d{1,2}/, ''
        line.gsub! /\s([A-Z]{3})$/, ''

        if number_match = /^\d{1,2}[stndrh]{2}\s+(\d{1,2})/.match(line)
            number = number_match.captures[0]
            line.gsub! /^\d{1,2}[stndrh]{2}\s+(\d{1,2})/, ''
        end

        line.strip!
    end
    head.reject!(&:empty?)

    #return nil unless number

    last_name = first_name = name = nil
    head.each do |line|
        # parse exceptions
        line.gsub! 'Juan Francisco GU', 'Juanfran Guevara'
        line.gsub! 'Niccolo ANTONELL', 'Niccolò ANTONELLI'
        line.gsub! 'Niccolò ANTONELLII', 'Niccolò ANTONELLI'
        line.gsub! 'Jesco RAFFIN', 'Jesko RAFFIN'
        # end

        arr = line.split
        next if arr.size < 2

        first_name = arr[0].capitalize
        last_name = arr[1].capitalize

        unless name = $people.find{|p| p[:first_name] == first_name && p[:last_name] == last_name}
            names = $people.find_all{|p| p[:first_name].include?(first_name) && p[:last_name].include?(last_name)}

            if names.size != 1
                next if arr.size < 3

                last_name = "#{arr[1].capitalize} #{arr[2].capitalize}"
                names = $people.find_all{|p| p[:first_name].include?(first_name) && p[:last_name].include?(last_name)}

                if names.size != 1
                    first_name = "#{arr[0].capitalize} #{arr[1].capitalize}"
                    last_name = arr[2].capitalize
                    names = $people.find_all{|p| p[:first_name].include?(first_name) && p[:last_name].include?(last_name)}
                    next if names.size != 1
                end
            end

            name = names[0]
        end

        break
    end

    return nil unless name

    head.collect! do |line|
        line.gsub(Regexp.new(first_name, true), '')
            .gsub(Regexp.new(last_name, true), '')
            .strip
    end
    team = head.reject(&:empty?).join(' ')

    { person_id: name[:id], first_name: name[:first_name], last_name: name[:last_name], number: number, team: team }
end

def process_file(filename)
    match = /(\d{4})\/(\d{2})_([A-Z]{3})\/[A-Z]{3}_([MotoGP01235c]+)_([A-Za-z0-9]{2,3})_analysis/.match(filename)
        
    return unless match

    year, sequence, event_name, category, session = match.captures

    circuit = $circuits.find {|c| c.name == event_name}
    event = Event.find_or_create_by(year: year, circuit_id: circuit.id, number: sequence)

    raw_lines = extract_lines(filename)

    raw_riders = split_riders(raw_lines)

    raw_riders.each do|r| 
        unless res = parse_rider(r)
            r[:file] = filename
            $error_raw_riders << r
            next
        end

        dump_rider res, event, category, session
    end

end

def dump_rider(r, event, category, session)
    context = {
        year: event.year,
        number: event.number,
        category: category,
        session: session
    }

    rider = Rider.find_by(person_id: r[:person_id], number: r[:number], team: r[:team], category: category)

    unless rider
        rider = Rider.find_by(person_id: r[:person_id], number: r[:number], team: r[:team], category: nil) 
        if rider
            rider.category = category
            rider.save
        else
            rider = Rider.create!(person_id: r[:person_id], number: r[:number], team: r[:team], category: category)
        end
    end

    puts "Creating laps for #{r[:first_name]} #{r[:last_name]}, #{event.year}, #{event.number}, #{category}, #{session}"

    r[:laps].each_with_index do |lap, i|
        l = Lap.create!(
            sequence: i+1, 
            time: lap[:lap], 
            t1: lap[:t1],
            t2: lap[:t2],
            t3: lap[:t3],
            t4: lap[:t4],
            speed: lap[:speed],
            pit: lap[:pit],
            finished: lap[:finished],
            session: session,
            rider: rider,
            event: event
            )
    end

end

def process_dir
    Dir.chdir $data_dir

    results = {}
    Dir['**/*.*'].each do |file|
        puts file
        process_file(file)
    end

    Dir.chdir '..'
end

#process_file("#{$data_dir}/2010/01_QAT/QAT_MotoGP_FP2_analysis.txt")
process_dir
#puts $test_data.map(&method(:parse_head)).to_yaml

File.open('error_raw_riders.yml', 'w') {|f| f.write $error_raw_riders.to_yaml }
