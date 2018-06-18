require 'active_record'
require 'active_support'
require 'yaml'

@db = YAML.load_file('db/config.yml')

# recursively requires all files in ./lib and down that end in .rb
Dir.glob('./models/*.rb').each do |file|
    require file
end

ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveSupport::LogSubscriber.colorize_logging = false
# tells AR what db file to use
ActiveRecord::Base.establish_connection(@db['development'])
