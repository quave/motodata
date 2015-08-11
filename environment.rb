require 'active_record'
require 'active_support'
# recursively requires all files in ./lib and down that end in .rb
Dir.glob('./models/*.rb').each do |file|
    require file
end

#ActiveRecord::B0ase.logger = Logger.new(STDOUT)
ActiveSupport::LogSubscriber.colorize_logging = false
# tells AR what db file to use
ActiveRecord::Base.establish_connection(
    adapter: 'postgresql',
    host: 'localhost',
#    port: 5439,
    port: 5432,
    database: 'motodata',
    username: 'postgres',
    #password: postgrespass
    pool: 5,
    timeout: 5000,
    encoding: 'utf-8'
)
