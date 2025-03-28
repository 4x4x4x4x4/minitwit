require_relative '../db/sequel'
require 'bcrypt'


module DatabaseHelper
  def self.new_user(username, email, password)
    pw_hash = BCrypt::Password.create(password)
    User.insert(username: username, email: email, pw_hash: pw_hash)  
  end

  def self.get_user_id(username)
    Usere.where(username: username).map(:user_id)
  end

  def self.new_message(user, message)
    Message.insert()
  end

  def self.get_messages(user,no_messages)

  end

  def self.follow(follower, followee)

  end

  def self.unfollow(follower, followee)

  end

  def self.get_followers(user)

  end

end
