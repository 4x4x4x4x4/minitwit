require 'sequel'

DB = Sequel.connect(
  adapter: 'postgres', 
  host: ENV['db_IP'], 
  database: ENV['db_name'], 
  user: 'postgres', 
  password: ENV['db_password'])


Dir["#{File.dirname(__FILE__)}/../models/*.rb"].each { |file| require file }
