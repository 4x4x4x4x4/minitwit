class User
    attr_reader :id, :username, :email, :password_hash
  
    def initialize(id:, username:, email:, password_hash:)
      @id = id
      @username = username
      @email = email
      @password_hash = password_hash
    end
  end