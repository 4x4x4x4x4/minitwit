require 'sqlite3'
require 'bcrypt'

module AuthHelper
  def db_connection
    SQLite3::Database.new('database/minitwit.db', results_as_hash: true)
  end

  def init_db
    db = SQLite3::Database.new 'database.db'
  
    # Open the schema.sql file and execute the SQL script
    File.open('schema.sql', 'r') do |file|
      db.execute_batch(file.read)
    end
  end

  def logged_in?
    !!session[:user_id]
  end

  def current_user
    return nil unless logged_in?
    
    db = db_connection
    user = db.execute('SELECT * FROM user WHERE user_id = ?', [session[:user_id]]).first
    db.close
    user
  end
end
