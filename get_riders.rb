require_relative 'environment'

require 'net/http'
require 'json'
require 'time'
require 'yaml'
require 'open-uri'
require 'nokogiri'


services_host = 'services.motogp.com'
site_host = 'www.motogp.com'

#proxy_addr = 'localhost'
#proxy_port = 3128
proxy_addr = nil
proxy_port =nil

services_http = Net::HTTP.new(services_host, nil, proxy_addr, proxy_port)
site_http = Net::HTTP.new(site_host, nil, proxy_addr, proxy_port)
#services_http.set_debug_output $stderr

services_http.start
site_http.start

save_rider = lambda do |first, last|
    person = Person.find_or_create_by first_name: first, last_name: last

    puts url = URI(URI::encode("http://www.motogp.com/en/riders/#{first.gsub(/\s+/, '+')}+#{last.gsub(/\s+/, '+')}"))
    html = site_http.get(url).body
    
    doc = Nokogiri::HTML(html)

    birth_place_element = doc.at_css('#rider_profile_topcontent .details p[title^="Place of birth"]')
    if birth_place_element
        person.birthplace = birth_place_element.text
    end

    country_element = doc.at_css('#rider_profile_topcontent .details img')
    if country_element
        person.country = country_element['alt']
    end

    person.save! if person.changed?
    puts "Person created #{person.inspect}"
    
    number_element = doc.at_css('#rider_profile_topcontent .details .number')
    team_element = doc.at_css("#rider_profile_topcontent .details .team")

    if number_element && team_element
        rider = Rider.create! person: person, number: number_element.text.to_i, team: team_element.text
        puts "Rider created #{rider.inspect}"
    end
end

('a'..'z').each do |letter|
    puts letter
    res = services_http.get(URI("http://#{services_host}/riders/complete?queryString=#{letter}&jsoncallback=cb")).body.gsub!(/(^cb\()|(\)$)/, '')
    json = JSON.parse(res)

    json['riders'].each do |rider|
        last_name, first_name = /goToUrl\('(.*), (.*)'\);/.match(rider).captures
        save_rider.call(first_name.capitalize, last_name.capitalize)
    end
end
