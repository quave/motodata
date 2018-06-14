require 'yaml'

al = YAML::load_file('people_aliases.yaml')
puts al[['Pol', 'ERGO']]
