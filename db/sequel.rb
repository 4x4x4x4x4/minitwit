require 'sequel'

DB = Sequel.sqlite('database/minitwit.db')
Dir["#{File.dirname(__FILE__)}/../models/*.rb"].each { |file| require file }
