require_relative '../db/sequel'
require 'bcrypt'


module DatabaseHelper
  def self.new_user(username, email, password)
    pw_hash = BCrypt::Password.create(password)
    User.insert(username: username, email: email, pw_hash: pw_hash)  
  end

  def self.get_user_id(username)
    User.where(username: username).get(:user_id)
  end

  def self.get_user(user_id)
    User.where(user_id: user_id).first
  end

  def self.check_user_password(user_id,password)
    pw_hash = User.where(user_id: user_id).get(:pw_hash)
    BCrypt::Password.new(pw_hash) == password
  end

  def self.new_message(username, message)
    user_id = self.get_user_id(username)
    Message.insert(author_id: user_id, text: message, flagged: 0)
  end

  def self.get_messages(no_messages)
    Message
      .join(:user, user_id: :author_id)
      .where(flagged: 0)
      .order(Sequel.desc(:pub_date))
      .limit(no_messages)
      .all  
  end

  def self.get_user_messages(user_id, no_messages)
    Message
      .join(:user, user_id: :author_id)
      .where(flagged: 0)
      .where(author_id: user_id)
      .order(Sequel.desc(:pub_date))
      .limit(no_messages)
      .all
  end

  def self.get_user_timeline(user_id, no_messages)
    followee_ids = get_followee_ids(user_id)
    Message
      .join(:user, user_id: :author_id)
      .where(flagged: 0)
      .where{
        (author_id == user_id) | 
        (followee_ids.has_key?(author_id))
      }
      .order(Sequel.desc(:pub_date))
      .limit(no_messages)
      .all
  end

  def self.follows(follower, followee) #returns true if follower follows followee
    Follower.where(who_id: follower, whom_id: followee).count > 0
  end

  def self.follow(follower, followee)
    Follower.insert(who_id: follower, whom_id: followee)
  end

  def self.unfollow(follower, followee)
    Follower.where(who_id: follower, whom_id: followee).delete
  end

  def self.get_followee_ids(user_id)
    Follower.where(who_id: user_id).as_hash(:whom_id)
  end
end
