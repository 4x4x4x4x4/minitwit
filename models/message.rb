class Message < Sequel::Model (:message)
  many_to_one :user  # Each message belongs to one user

  # Sequel automatically maps columns, no need for an explicit initialize method
end

