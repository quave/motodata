require 'net/http'
require 'json'
require 'time'
require 'yaml'
require 'open-uri'
require 'nokogiri'

host = 'www.motogp.com'
base_url = "/en/ajax/results/"
selector = 'selector/'
files = 'files'
start_year = 2010

proxy_addr = 'localhost'
proxy_port = 3128
result_dir = 'pdf'

Dir.mkdir(result_dir) unless File.exists?(result_dir)
Dir.chdir result_dir

Net::HTTP.start(host, nil, proxy_addr, proxy_port) do |http|
    get_json = Proc.new do |url|
        puts "\n#{url}"

        result = http.get(url).body
        puts "#{result}"

        JSON.parse(result)
    end

    save_file = Proc.new do |event, gp_class, ride, file_type, url|
        file_name = "#{event}_#{gp_class}_#{ride}_#{file_type}.pdf"

        open(file_name, 'wb') do |file|
            resp = http.get(URI(url)) do |str|
                file << str
            end
        end
    end

    (start_year..Time.now.year).each do |year|
        year_dir = year.to_s
        Dir.mkdir(year_dir) unless File.exists?(year_dir)
        Dir.chdir year_dir

        process_event = Proc.new do |event, i|
            event_dir = "#{(i+1).to_s.rjust(2, '0')}_#{event['shortname']}"
            Dir.mkdir(event_dir) unless File.exists?(event_dir)
            Dir.chdir event_dir

            url = URI("http://#{host}/#{event['url']}")
            result = get_json.call(url)

            process_ride = Proc.new do |ride, gp_class|
                puts
                puts ride
                puts url = URI("http://#{host}#{base_url}#{files}/#{year}/#{event['shortname']}/#{gp_class}/#{ride['value']}")
                html = http.get(url).body
                files_doc = Nokogiri::HTML(html)

                analysis_element = files_doc.at_css(".lista_pdf a[title='Download Analysis PDF']")
                if analysis_element
                    puts file_url = analysis_element['href']
                    save_file.call(event['shortname'], gp_class, ride['value'], 'analysis', file_url)
                else
                    puts 'No Analysis found'
                end

                if ride['value'] == 'RAC'
                    lap_chart_element = files_doc.at_css(".lista_pdf a[title='Download Lap Chart PDF']")
                    if lap_chart_element
                        puts file_url = lap_chart_element['href']
                        save_file.call(event['shortname'], gp_class, ride['value'], 'lapchart', file_url)
                    else
                        puts 'No Lap Chart found'
                    end
                end
            end

            result.each do |gp_class|
                 get_json.call(gp_class['url']).each { |ride| process_ride.call(ride, gp_class['name']) }
            end

            Dir.chdir '..'
        end

        url = URI("http://#{host}/#{base_url}#{selector}#{year}")

        parsed = get_json.call(url)
        puts "events: #{parsed.size}"

        events = parsed.map { |k, v| v }

        events.each_with_index &process_event

        Dir.chdir '..'
    end
end

Dir.chdir '..'
