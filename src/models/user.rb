require 'sequel'

class User < Sequel::Model(:user)
  one_to_many :message
  plugin :timestamps, update_on_create: true
end

