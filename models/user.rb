require 'sequel'

class User < Sequel::Model(:user)
  one_to_many :messages
  plugin :timestamps, update_on_create: true
end

