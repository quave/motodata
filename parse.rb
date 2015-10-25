require 'time'
require 'open-uri'
require 'yaml'
require_relative 'environment'
require_relative 'sequence'
require 'pluck_to_hash'

puts 'Ok starting'
$data_dir = 'data'
$errors = []
$circuits = Circuit.all.to_a
$people = Person.all.pluck_h(:id, :first_name, :last_name, :country)
$countries = $people.map{|p| p[:country]}.uniq.find_all{ |c| /^[A-Z]{3}$/ =~ c }
$people_aliases = YAML::load_file('people_aliases.yaml')

# debug options
$skip_lap_inserting = true
$skip_dump_riders = true
$file_to_process = '2011/12_INP/INP_Moto2_WUP_analysis.txt'
$lap_regex = /^[\d'.\sbPITunfinished]+\.[\d'.\sPITb]+$/
$head_start_regex = /^\d{1,2}(\s|$)/
puts 'Data loaded'

def drop_error(msg, data = nil, context = nil) 
    $errors << {msg: msg, data: data, context: context}
end

$seq = Sequence.new(false)

$seq.add :process_dir do |dir, &process_file|
    puts "Start with dir #{dir}"
    Dir.chdir dir

    results = {}

    Dir['**/*_analysis.txt'].each &process_file
    
    Dir.chdir '..'
    true
end

$seq.add :process_file do |file, &split_riders|
    puts "Parse #{file}"
        match = /(\d{4})\/(\d{2})_([A-Z]{3})\/[A-Z]{3}_([MotoGP01235c]+)_([A-Za-z0-9]{2,3}(\d)?)_analysis/.match(file)
        
    unless match
        drop_error('Unknown file name format', file)
        next false
    end

    year, sequence, event_name, category, session = match.captures

    circuit = $circuits.find {|c| c.name == event_name}
    event = Event.find_or_create_by(year: year, circuit_id: circuit.id, number: sequence)

    lines = File.open(file).read.force_encoding('utf-8')
        .split("\f") # split file into pdf pages
        .map do |page| # strip data on pages
            head = page.lines.take_while { |l| l !~ $lap_regex }
            start_index = head.rindex { |l| l =~ $head_start_regex && l !~ /^18 Garage/i } || head.size

            page.lines[start_index..-1]
                .take_while {|l| l !~ /^Page/ } # strip ending trash
                .map { |l| l.strip.gsub(/\n/, '') } # normalize strings
        end
        .flatten # merge pages

    split_riders.call(lines, {event: event, category: category, session: session})

    true
end

$seq.add :split_riders do |lines, context, &parse_rider|
    while lines.size > 0
        rider = [lines.shift] + lines.take_while { |l| l !~ $head_start_regex || l =~ /^18 Garage/i }
        lines = lines.drop(rider.size-1)

        parse_rider.call(rider, context)
    end 

    true
end

class RawRiderHelper
    def self.extract_person(head)
        first_name = last_name = country = nil
	head_regex = /
            \b(?<country>[A-Z]{3})
	    (?<first>
                (
		    ([A-Z]{1})?
		    [\u{00C0}-\u{01FF}a-z'\-]+
		    \b\s?
                )+\s?
            )\s
            (?<last>
                [c\u{00C0}-\u{01FF}'\-A-Z\s]+
            )\b
	/ux

        if match = head_regex.match(head)
            country = match[:country] 
            first_name = match[:first]
            last_name = match[:last]
        end

	unless $countries.include?(self.remap_country(country))
            puts "Country #{country} not found for head #{head}"
	    return nil
	end

        unless first_name && last_name && country
            puts "Unable to parse head #{head}"
            return nil
        end

        self.find_person(first_name, last_name, country)
    end

    def self.remap_country(country) 
        case country
            when 'SUI'
                'SWI'
            when 'DAN'
                'DEN'
            when 'ROM'
                'ROU'
            when 'SLK'
                'SVK'
            else
                country
            end
    end

    def self.remap_person(first_name, last_name)
	input = [first_name, last_name]
	$people_aliases[input] || input
    end

    def self.find_person(first, last, country)
        first, last = self.remap_person(first, last)
        person = $people.find { |p| p[:first_name] =~ /^#{first}/i && p[:last_name] =~ /^#{last}/i }

        unless person
            puts "Unable to find name #{first} #{last}"
            return nil
        end

        if person[:country] && country && 
            person[:country] != RawRiderHelper.remap_country(country)
            puts "Rider country collsion rider:#{person[:country]}, #{person[:first_name]} #{person[:last_name]}, extracted remaped country:#{RawRiderHelper.remap_country(country)}"
        end
        person
    end
end

$seq.add :parse_rider do |raw, context, &dump_rider|
    rider = { }

    res_lines, head_lines = raw.partition {|l| $lap_regex =~ l}
    puts head_lines.join(' ')
    head = head_lines[0..1].join(' ')

    if match = $head_start_regex.match(head)
        rider[:number] = match[0].to_i
        head = head.gsub($head_start_regex, '')
    end

    person = RawRiderHelper.extract_person(head)

    unless person
        drop_error('Unable to extract person', raw, context)
    end

    rider[:team] = head.gsub(/#{rider[:first_name]}/i, '').gsub(/#{rider[:last_name]}/i, '').strip

    failed = false
    rider[:laps] = res_lines.map do |line|
        match = /^
            (
                (?<time>(\d{1,2}')?\d{1,2}\.\d{4,5}) |
                (?<unf>unfinished)(1)?
            )?
            (\s+)?
            (
                (?<t1>(\d{1,2}')?\d{1,2}\.\d{3})
                (?<pit1>P|PIT)?
                (b)?
            )?
            (\s+
                (?<t2>(\d{1,2}')?\d{1,2}\.\d{3})
                (?<pit2>P|PIT)?
                (b)?
            )?
            (\s+
                (?<t3>(\d{1,2}')?\d{1,2}\.\d{3})
                (?<pit3>P|PIT)?
                (b)?
            )?
            (
                \s+(?<speed>\d{2,3}\.\d)?
                (b(\s+|$))?
                (?<pit4>(P|PIT)(\s+)?)?
                (?<t4>(\d{1,2}')?\d{2}\.\d{3})?
            )?
        $/x.match(line)

        unless match
            puts "Unable to parse line\n#{line}\n"
            drop_error("Unable to parse line\n#{line}\n", raw, context)
            break
        end

        {
            unfinished: match[:unf] == 'unfinished',
            time: match[:time],
            t1: match[:t1],
            t2: match[:t2],
            t3: match[:t3],
            t4: match[:t4],
            speed: match[:speed]
        }
    end

    next false if failed

    dump_rider.call(rider, context) unless $skip_dump_riders

    true
end


$seq.add :dump_rider do |rider, context, &insert_lap|
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

    context[:rider] = rider

    puts "Creating laps for #{r[:first_name]} #{r[:last_name]}, #{event.year}, #{event.number}, #{category}, #{session}"

    r[:laps].each_with_index do |lap, i|
        context[:sequence] = i + 1
        insert_lap.call(lap, context)
    end unless $skip_lap_inserting

    next true
end

$seq.add :insert_lap do |lap, context| 
    Lap.create!(
        sequence: context[:sequence], 
        time: lap[:lap], 
        t1: lap[:t1],
        t2: lap[:t2],
        t3: lap[:t3],
        t4: lap[:t4],
        speed: lap[:speed],
        pit: lap[:pit],
        finished: lap[:finished],
        session: context[:session],
        rider: context[:rider],
        event: context[:event]
        )

    next true
end

if $file_to_process
    $seq.run("#{$data_dir}/#{$file_to_process}", 1)
else
    $seq.run($data_dir)
end

puts "Errors: #{$errors.size}"
File.open('errors.yaml', 'w') { |f| f.write($errors.to_yaml) }
