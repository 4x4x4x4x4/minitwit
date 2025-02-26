require_relative '../repositories/message_repository'

class MessageService
  def self.fetch_timeline(user_id)
    MessageRepository.get_messages_for_timeline(user_id, 30)
  end

  def self.post_message(user_id, text)
    return if text.strip.empty?
    MessageRepository.add_message(user_id, text)
  end
end
