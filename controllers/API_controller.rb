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
end