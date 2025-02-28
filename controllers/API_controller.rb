require 'sinatra'
require 'sqlite3'
require 'bcrypt'
require 'json'

class APIController < Sinatra::Base
  
  helpers do
    def db_connection
        SQLite3::Database.new('database/minitwit.db', results_as_hash: true)
    end

    #Helper function to check authorization
    def not_req_from_simulator(request)
      from_simulator = request.env["HTTP_AUTHORIZATION"]
      if from_simulator != "Basic c2ltdWxhdG9yOnN1cGVyX3NhZmUh"
        error = "You are not authorized to use this resource!"
        return [403, { "Content-Type" => "application/json" }, [{ status: 403, error_msg: error }.to_json]]
      end
      nil
    end

    def get_user_id(username)
      db = db_connection
      db.results_as_hash = true
      result = db.execute("SELECT user_id FROM user WHERE username = ?", [username]).first
      db.close
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
    content_type :json
    @db = db_connection
  end

  after do
    @db.close if @db
  end


  get '/latest' do
     begin
       content = File.read('./latest_processed_sim_action_id.txt')
       latest_processed_command_id = Integer(content)
     rescue
       latest_processed_command_id = -1
     end
     { latest: latest_processed_command_id }.to_json
   end

  post'/register' do
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
end