require 'sequel'

# Connect to old SQLite DB
old_db = Sequel.connect('sqlite://path/to/your_old_sqlite.db')

# Connect to new PostgreSQL DB
new_db = Sequel.connect(ENV['DATABASE_URL'])

old_db[:user].each do |row|
  new_db[:user].insert(row)
end

old_db[:follower].each do |row|
  new_db[:follower].insert(row)
end

old_db[:messages].each do |row|
  new_db[:messages].insert(row)
end
