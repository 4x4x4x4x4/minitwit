require 'sequel'

class User < Sequel::Model
  one_to_many :messages  # A user has many messages

  # If you want to automatically handle timestamps
  plugin :timestamps, update_on_create: true
end

