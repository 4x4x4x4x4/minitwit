require 'sinatra'
require 'sqlite3'
require 'bcrypt'
require 'time'

# Configuration
DB_FILE = File.join(File.dirname(__FILE__), 'database', 'minitwit.db')
PER_PAGE = 30

use Rack::Session::Cookie, key: 'rack.session',
                           path: '/',
                           secret: SecureRandom.hex(64)


helpers do
  def db_connection
    SQLite3::Database.new(DB_FILE, results_as_hash: true)
  end

  def logged_in?
    !!session[:user_id]
  end

  def gravatar(email, size: 48)
    hash = Digest::MD5.hexdigest(email.strip.downcase)
    "https://www.gravatar.com/avatar/#{hash}?s=#{size}&d=identicon"
  end

  def current_user
    return nil unless logged_in?
    db = db_connection
    db.execute('SELECT * FROM user WHERE user_id = ?', [session[:user_id]]).first
  end

  def format_datetime(timestamp)
    Time.at(timestamp.to_i).utc.strftime('%Y-%m-%d @ %H:%M')
  end
end

before do
  @db = db_connection
  puts "Session User ID: #{session[:user_id].inspect}" 
  @user = current_user
  puts "Current User: #{@current_user.inspect}"
  puts "User: #{@user.inspect}"
end

after do
  @db.close if @db
end

# Home / Timeline
get '/' do
  redirect '/public' unless logged_in?

  @messages = @db.execute(
    "SELECT message.*, user.* FROM message 
    JOIN user ON message.author_id = user.user_id 
    WHERE message.flagged = 0 AND 
    (user.user_id = ? OR user.user_id IN 
      (SELECT whom_id FROM follower WHERE who_id = ?))
    ORDER BY message.pub_date DESC LIMIT ?",
    [session[:user_id], session[:user_id], PER_PAGE]
  )
  
  erb :timeline
end

# Public Timeline
get '/public' do
  @messages = @db.execute(
    "SELECT message.*, user.* FROM message 
    JOIN user ON message.author_id = user.user_id 
    WHERE message.flagged = 0 
    ORDER BY message.pub_date DESC LIMIT ?", [PER_PAGE]
  )
  
  erb :timeline
end

# Login
get '/login' do
  erb :login
end

post '/login' do
  user = @db.execute("SELECT * FROM user WHERE username = ?", [params[:username]]).first

  if user && BCrypt::Password.new(user['pw_hash']) == params[:password]
    session[:user_id] = user['user_id']
    redirect '/'
  else
    @error = "Invalid credentials"
    erb :login
  end
end

# Register
get '/register' do
  redirect '/' if logged_in?
  erb :register
end

post '/register' do
  if params[:password] != params[:password2]
    @error = "Passwords do not match"
    erb :register
  else
    pw_hash = BCrypt::Password.create(params[:password])
    @db.execute("INSERT INTO user (username, email, pw_hash) VALUES (?, ?, ?)", 
                [params[:username], params[:email], pw_hash])
    redirect '/login'
  end
end

# Add a new message
post '/add_message' do
  halt 401 unless logged_in?

  if params[:text] && !params[:text].empty?
    @db.execute("INSERT INTO message (author_id, text, pub_date, flagged) VALUES (?, ?, ?, 0)", 
                [session[:user_id], params[:text], Time.now.to_i])
  end
  
  redirect '/'
end

# Logout
get '/logout' do
  session.clear
  redirect '/public'
end

# User Timeline
get '/:username' do
  @profile_user = @db.execute("SELECT * FROM user WHERE username = ?", [params[:username]]).first
  halt 404 unless @profile_user

  @messages = @db.execute(
    "SELECT message.*, user.* FROM message 
    JOIN user ON message.author_id = user.user_id 
    WHERE user.user_id = ? 
    ORDER BY message.pub_date DESC LIMIT ?", 
    [@profile_user['user_id'], PER_PAGE]
  )

  erb :timeline
end

# Follow a user
get '/:username/follow' do
  halt 401 unless logged_in?

  whom_id = @db.execute("SELECT user_id FROM user WHERE username = ?", [params[:username]]).first
  halt 404 unless whom_id

  @db.execute("INSERT INTO follower (who_id, whom_id) VALUES (?, ?)", [session[:user_id], whom_id['user_id']])
  redirect "/#{params[:username]}"
end

# Unfollow a user
get '/:username/unfollow' do
  halt 401 unless logged_in?

  whom_id = @db.execute("SELECT user_id FROM user WHERE username = ?", [params[:username]]).first
  halt 404 unless whom_id

  @db.execute("DELETE FROM follower WHERE who_id = ? AND whom_id = ?", [session[:user_id], whom_id['user_id']])
  redirect "/#{params[:username]}"
end