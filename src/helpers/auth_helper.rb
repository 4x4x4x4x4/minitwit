require 'sqlite3'
require 'bcrypt'

module AuthHelper
  def valid_email(email)
    email.include?('@') ? true : false
  end

  def logged_in?
    !!session[:user_id]
  end

  def current_user
    return nil unless logged_in?
    
    DatabaseHelper.get_user(session[:user_id])
  end
end
