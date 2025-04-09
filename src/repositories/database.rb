require 'sqlite3'

class Database
  DB_FILE = File.join(File.dirname(__FILE__), '../../database/minitwit.db')

  def self.connection
    SQLite3::Database.new(DB_FILE, results_as_hash: true)
  end
end