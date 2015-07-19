require_relative 'environment'

puts Person.find_or_create_by(first_name: 'Roger', last_name: 'Lee Hayden')