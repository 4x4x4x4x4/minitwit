require_relative 'database'

class UserRepository
  def self.find_by_username(username)
    db = Database.connection
    result = db.execute("SELECT * FROM user WHERE username = ?", [username]).first
    db.close
    return nil unless result
    User.new(id: result['user_id'], username: result['username'], email: result['email'], password_hash: result['pw_hash'])
  end

  def self.find_by_id(id)
    db = Database.connection
    result = db.execute("SELECT * FROM user WHERE user_id = ?", [id]).first
    db.close
    return nil unless result
    User.new(id: result['user_id'], username: result['username'], email: result['email'], password_hash: result['pw_hash'])
  end

  def self.create(username, email, password_hash)
    db = Database.connection
    db.execute("INSERT INTO user (username, email, pw_hash) VALUES (?, ?, ?)", [username, email, password_hash])
    db.close
  end
end
