class Message < Sequel::Model (:message)
  many_to_one :user  # Each message belongs to one user
end

