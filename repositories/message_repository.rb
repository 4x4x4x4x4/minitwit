require_relative 'database'

class MessageRepository
  def self.get_messages_for_timeline(user_id, limit)
    db = Database.connection
    messages = db.execute(
      "SELECT message.*, user.* FROM message 
       JOIN user ON message.author_id = user.user_id 
       WHERE message.flagged = 0 AND 
       (user.user_id = ? OR user.user_id IN 
         (SELECT whom_id FROM follower WHERE who_id = ?))
       ORDER BY message.pub_date DESC LIMIT ?",
      [user_id, user_id, limit]
    )
    db.close
    messages
  end

  def self.add_message(author_id, text)
    db = Database.connection
    db.execute("INSERT INTO message (author_id, text, pub_date, flagged) VALUES (?, ?, ?, 0)",
               [author_id, text, Time.now.to_i])
    db.close
  end
end
