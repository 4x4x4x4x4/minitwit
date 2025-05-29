require 'sequel'

# Connect to old SQLite DB
old_db = Sequel.connect('sqlite://app/database/minitwit.db')

# Connect to new PostgreSQL DB
new_db = Sequel.connect(
  adapter: 'postgres', 
  host: ENV['db_IP'], 
  database: ENV['db_name'], 
  user: 'postgres', 
  password: ENV['db_password'])

old_db[:user].each do |row|
  new_db[:user].insert(row)
end

old_db[:follower].each do |row|
  new_db[:follower].insert(row)
end

old_db[:messages].each do |row|
  new_db[:messages].insert(row)
end
