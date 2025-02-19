require 'bcrypt'
require_relative '../repositories/user_repository'

class AuthService
  def self.authenticate(username, password)
    user = UserRepository.find_by_username(username)
    return nil unless user
    return user if BCrypt::Password.new(user.password_hash) == password
    nil
  end
end
