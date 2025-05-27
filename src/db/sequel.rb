require 'sequel'

DB = Sequel.connect(
  adapter: 'postgres', 
  host: ENV['db_IP'], 
  database: ENV['db_name'], 
  user: 'postgres', 
  password: ENV['db_password'])

# Create 'user' table
DB.create_table? :user do
  primary_key :user_id
  String :username, null: false
  String :email, null: false
  String :pw_hash, null: false
end

DB.create_table? :follower do
  Integer :who_id
  Integer :whom_id
end

DB.create_table? :message do
  primary_key :message_id
  Integer :author_id, null: false
  String :text, null: false
  Integer :pub_date
  Integer :flagged
end

Dir["#{File.dirname(__FILE__)}/../models/*.rb"].each { |file| require file }
