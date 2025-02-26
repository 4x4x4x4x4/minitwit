require 'fileutils'     # os module
require 'time'          # time module
require 'sqlite3'       # sqlite3 module
# require 'digest/md5'    # hashlib.md5
# require 'pathname'      # pathlib.Path
require 'date'          # datetime
require 'json'          # JSON
require 'sinatra'       # Flask
require 'bcrypt'        # Equivalent to werkzeug.security password hashing

DATABASE = "/database/minitwit.db" # Path to the database file
SIM = "latest_processed_sim_action_id.txt" # Path to the sim_action file
DEBUG = true

# Delete database for testing
File.delete(DATABASE) if File.exist?(DATABASE)
File.delete(SIM) if File.exist?(SIM)

# Create a basic Sinatra application
set :root, File.dirname(__FILE__)  # Set the root path for the app

# Configuration (equivalent to Flask's app.config.from_object)
configure do
  set :app_secret, 'your_secret_key'
  set :environment, :development
  set :debug, DEBUG
end

# Helper function to check authorization
def not_req_from_simulator(request)
  from_simulator = request.env["HTTP_AUTHORIZATION"]
  if from_simulator != "Basic c2ltdWxhdG9yOnN1cGVyX3NhZmUh"
    error = "You are not authorized to use this resource!"
    return [403, { "Content-Type" => "application/json" }, [{ status: 403, error_msg: error }.to_json]]
  end
  nil
end

# Helper function to get user_id by username
def get_user_id(username)
  db = SQLite3::Database.new(DATABASE)
  result = db.execute("SELECT user_id FROM user WHERE username = ?", [username])
  db.close
  result.empty? ? nil : result[0][0]
end

# Ensure DB connection is available for each request
before do
  @db = SQLite3::Database.new(DATABASE)
end

# Close DB connection after each request
after do
  @db.close
end

# Update the latest processed command ID
def update_latest(request)
  parsed_command_id = request.params['latest'].to_i
  if parsed_command_id != -1
    File.write(SIM, parsed_command_id.to_s)
  end
end

# Get the latest processed command ID
get '/latest' do
  begin
    content = File.read(SIM)
    latest_processed_command_id = Integer(content)
  rescue
    latest_processed_command_id = -1
  end
  { latest: latest_processed_command_id }.to_json
end

# Register a new user
post '/register' do
  update_latest(request)

  request_data = JSON.parse(request.body.read)
  error = nil
  if !request_data["username"]
    error = "You have to enter a username"
  elsif !request_data["email"] || !request_data["email"].include?("@")
    error = "You have to enter a valid email address"
  elsif !request_data["pwd"]
    error = "You have to enter a password"
  elsif get_user_id(request_data["username"])
    error = "The username is already taken"
  else
    hashed_password = BCrypt::Password.create(request_data["pwd"])
    @db.execute("INSERT INTO user (username, email, pw_hash) VALUES (?, ?, ?)", [request_data["username"], request_data["email"], hashed_password])
  end

  if error
    status 400
    { status: 400, error_msg: error }.to_json
  else
    status 204
    body ''
  end
end

# Get messages
get '/msgs' do
  update_latest(request)

  not_from_sim_response = not_req_from_simulator(request)
  return not_from_sim_response if not_from_sim_response

  no_msgs = params['no'].to_i || 100
  query = "SELECT message.*, user.* FROM message, user WHERE message.flagged = 0 AND message.author_id = user.user_id ORDER BY message.pub_date DESC LIMIT ?"
  messages = @db.execute(query, [no_msgs])

  filtered_msgs = messages.map do |msg|
    {
      content: msg['text'],
      pub_date: msg['pub_date'],
      user: msg['username']
    }
  end

  filtered_msgs.to_json
end

# Get or post messages for a specific user
get '/msgs/:username' do
  update_latest(request)

  not_from_sim_response = not_req_from_simulator(request)
  return not_from_sim_response if not_from_sim_response

  username = params[:username]
  user_id = get_user_id(username)
  return status 404 if user_id.nil?

  no_msgs = params['no'].to_i || 100
  query = "SELECT message.*, user.* FROM message, user WHERE message.flagged = 0 AND user.user_id = message.author_id AND user.user_id = ? ORDER BY message.pub_date DESC LIMIT ?"
  messages = @db.execute(query, [user_id, no_msgs])

  filtered_msgs = messages.map do |msg|
    {
      content: msg['text'],
      pub_date: msg['pub_date'],
      user: msg['username']
    }
  end

  filtered_msgs.to_json
end

# Follow or unfollow a user
post '/fllws/:username' do
  update_latest(request)

  not_from_sim_response = not_req_from_simulator(request)
  return not_from_sim_response if not_from_sim_response

  username = params[:username]
  user_id = get_user_id(username)
  return status 404 if user_id.nil?

  if request_data = JSON.parse(request.body.read)
    if request_data["follow"]
      follows_username = request_data["follow"]
      follows_user_id = get_user_id(follows_username)
      return status 404 if follows_user_id.nil?

      @db.execute("INSERT INTO follower (who_id, whom_id) VALUES (?, ?)", [user_id, follows_user_id])
    elsif request_data["unfollow"]
      unfollows_username = request_data["unfollow"]
      unfollows_user_id = get_user_id(unfollows_username)
      return status 404 if unfollows_user_id.nil?

      @db.execute("DELETE FROM follower WHERE who_id = ? AND whom_id = ?", [user_id, unfollows_user_id])
    end
  end

  status 204
end

# Start Sinatra app
set :port, 5001
run! if __FILE__ == $0
