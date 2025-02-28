require 'sinatra'
require 'sqlite3'
require 'bcrypt'
require 'json'

class APIController < Sinatra::Base
  
  helpers do
    def db_connection
        SQLite3::Database.new('database/minitwit.db', results_as_hash: true)
    end

    def get_user_id(username)
      @db.results_as_hash = true
      result = @db.execute("SELECT user_id FROM user WHERE username = ?", [username]).first
      result ? result['user_id'] : nil
    end  

    def update_latest(request)
        parsed_command_id = request.params.fetch('latest', -1).to_i
        if parsed_command_id != -1
          File.open('./latest_processed_sim_action_id.txt', 'w') do |file|
            file.write(parsed_command_id.to_s)
          end
        end
    end


  end

  before do
    @db = db_connection
  end

  after do
    @db.close if @db
  end

  get '/api/latest' do
    content = File.read('./latest_processed_sim_action_id.txt') rescue '-1'
    latest_processed_command_id = content.to_i
    {latest: latest_processed_command_id }.to_json
  end

  post '/api/register' do
    update_latest(request)    
    content_type :json
    
    # Parse JSON body
    request_payload = JSON.parse(request.body.read) rescue {}

    params_values = [:username, :password, :password, :email].map { |param| params[param]&.strip }

    # Assigning to individual variables
    username, password, password2, email = params_values

    # Check required fields
    if username.nil? || username.empty?
      halt 400, { error: 'Username is required' }.to_json
    end
  
    if email.nil? || email.empty?
      halt 400, { error: 'Email is required' }.to_json
    end
  
    if password.nil? || password.empty?
      halt 400, { error: 'Password is required' }.to_json
    end
  
    # Check if passwords match
    if password != password2
      halt 400, { error: 'Passwords do not match' }.to_json
    end
  
    # Check if username already exists
    if get_user_id(username)
      halt 409, { error: 'Username is already taken' }.to_json
    end
  
    begin
      # Attempt to create user
      pw_hash = BCrypt::Password.create(password)

      @db.execute("INSERT INTO user (username, email, pw_hash) VALUES (?, ?, ?)", 
                  [username, email, pw_hash])
      
      # Assuming user insertion is successful
      user_id = get_user_id(username)  # Retrieve the ID of the newly created user
      if user_id
        status 204
        { user_id: user_id, username: username, email: email }.to_json
      else
        halt 400, { error: 'error' }.to_json
      end
    rescue SQLite3::Exception => e
      halt 500, { error: "Database error: #{e.message}" }.to_json
    end
  end

  get '/api/msgs' do
    update_latest(request)    
    content_type :json
    
    # Parse JSON body
    request_payload = JSON.parse(request.body.read) rescue {}
    # !!!check for sim HERE!!!
    #
    params_values = [:no, :latest].map { |param| params[param]&.strip }
    no, latest = params_values


    begin
      query = "SELECT message.*, user.* FROM message, user
        WHERE message.flagged = 0 AND message.author_id = user.user_id
        ORDER BY message.pub_date DESC LIMIT ?"
      msgs = @db.execute(query, [no.to_i])

      filtered_msgs = []
      msgs.each do |msg|
        filtered_msg = {}
        filtered_msg["content"] = msg["text"]
        filtered_msg["pub_date"] = msg["pub_date"]
        filtered_msg["user"] = msg["username"]
        filtered_msgs << filtered_msg
      end

      filtered_msgs.to_json #returns
    end
  end

  get '/api/msgs/:username' do
    update_latest(request)    
    content_type :json
    
    # Parse JSON body
    request_payload = JSON.parse(request.body.read) rescue {}
    # !!!check for sim HERE!!!
    #
    params_values = [:no, :latest].map { |param| params[param]&.strip }
    no, latest = params_values
    user_id = get_user_id(params[:username])


    begin
      query = "SELECT message.*, user.* FROM message, user
        WHERE message.flagged = 0 AND message.author_id = user.user_id AND user.user_id = ?
        ORDER BY message.pub_date DESC LIMIT ?"
      msgs = @db.execute(query, [user_id, no.to_i])

      filtered_msgs = []
      msgs.each do |msg|
        filtered_msg = {}
        filtered_msg["content"] = msg["text"]
        filtered_msg["pub_date"] = msg["pub_date"]
        filtered_msg["user"] = msg["username"]
        filtered_msgs << filtered_msg
      end

      filtered_msgs.to_json #returns
    end
  end
  
  post '/api/msgs/:username' do
    update_latest(request)
    content_type :json
    
    # Parse JSON body
    request_payload = JSON.parse(request.body.read) rescue {}
    # !!!check for sim HERE!!!
    #
    content = params[:content]&.strip
    user_id = get_user_id(params[:username])

    query = "INSERT INTO message (author_id, text, pub_date, flagged)
                   VALUES (?, ?, ?, 0)"
    
    @db.execute(query, [user_id, content, Time.now.to_i])
  end

  get '/api/fllws/:username' do
    params_values = [:no, :latest].map { |param| params[param]&.strip }
    no, latest = params_values
    user_id = get_user_id(params[:username])

    query = "SELECT user.username FROM user
                   INNER JOIN follower ON follower.whom_id=user.user_id
                   WHERE follower.who_id=?
                   LIMIT ?"

    followers = @db.execute(query, [user_id, no ? no.to_i : 100]) #if no was not set default to 100
    follower_names = followers.map { |e| e["username"] }
    followers_response = {"follows": follower_names}
    followers_response.to_json
  end

  post '/api/fllws/:username' do
    user_id = get_user_id(params[:username])
    if user_id.nil?
      halt 404
    end

    if params.key?("follow") 
      query = "INSERT INTO follower (who_id, whom_id) VALUES (?, ?)"
      fllw_id = get_user_id(params[:follow])
    elsif params.key?("unfollow")
      query = "DELETE FROM follower WHERE who_id=? and WHOM_ID=?"
      fllw_id = get_user_id(params[:unfollow])
    end
    
    if fllw_id.nil?
      halt 404
    end
    status 204
    @db.execute(query, [user_id, fllw_id])
  end
end
