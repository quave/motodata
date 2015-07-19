require 'net/http'
require 'json'
require 'time'
require 'yaml'
require 'open-uri'
require 'nokogiri'
require_relative 'environment'

host = 'www.motogp.com'
base_url = "/en/ajax/results/"
selector = 'selector/'
start_year = 1998

proxy_addr = 'localhost'
proxy_port = 3128

Net::HTTP.start(host, nil, proxy_addr, proxy_port) do |http|
    get_json = Proc.new do |url|
        puts "\n#{url}"

        result = http.get(url).body
        puts "#{result}"

        JSON.parse(result)
    end

    Time.now.year.downto(start_year).each do |year|

        process_event = Proc.new do |event, i|
            unless Circuit.exists?(name: event['shortname'])
                c = Circuit.create! name: event['shortname'], long_name: event['circuit']
                puts c.inspect
            end
        end

        url = URI("http://#{host}/#{base_url}#{selector}#{year}")

        parsed = get_json.call(url)
        puts "events: #{parsed.size}"

        events = parsed.map { |k, v| v }
        
        events.each_with_index &process_event

    end
end

