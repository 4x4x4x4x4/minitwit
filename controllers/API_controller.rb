require 'sinatra'
require 'sqlite3'
require 'bcrypt'
require 'json'
require_relative '../helpers/db_helper'


class APIController < Sinatra::Base
  
  helpers do

    #Helper function to check authorization
    def not_req_from_simulator(request)
      from_simulator = request.env["HTTP_AUTHORIZATION"]
      if from_simulator != "Basic c2ltdWxhdG9yOnN1cGVyX3NhZmUh"
        error = "You are not authorized to use this resource!"
        return [403, { "Content-Type" => "application/json" }, [{ status: 403, error_msg: error }.to_json]]
      end
      nil
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

    params_values = ["username", "pwd", "pwd", "email"].map { |param| request_payload[param]&.strip }
    
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
    if DatabaseHelper.get_user_id(username)
      halt 409, { error: 'Username is already taken' }.to_json
    end
  
    begin
      # Attempt to create user
      DatabaseHelper.new_user(username, email, password)
      
      # Assuming user insertion is successful
      user_id = DatabaseHelper.get_user_id(username)  # Retrieve the ID of the newly created user
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
    
    not_from_sim_response = not_req_from_simulator(request)
    if not_from_sim_response
      return not_from_sim_response
    end

    # Parse JSON body
    request_payload = JSON.parse(request.body.read) rescue {}
    
    no = params[:no]&.strip
    latest = params[:latest]&.strip


    begin
      msgs = DatabaseHelper.get_messages([no ? no.to_i : 100])


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

    not_from_sim_response = not_req_from_simulator(request)
    if not_from_sim_response
      return not_from_sim_response
    end
    
    no = params[:no]&.strip
    latest = params[:latest]&.strip
    user_id = DatabaseHelper.get_user_id(params[:username])

    begin
      msgs = DatabaseHelper.get_user_messages(user_id, no.to_i)

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
    
    not_from_sim_response = not_req_from_simulator(request)
    if not_from_sim_response
      return not_from_sim_response
    end
    
    # Parse JSON body
    request_payload = JSON.parse(request.body.read) rescue {}
    content = request_payload["content"]&.strip
    user_id = DatabaseHelper.get_user_id(params[:username])
    DatabaseHelper.new_message(user_id, content)   
  end

  get '/api/fllws/:username' do
    update_latest(request)
    content_type :json
    
    not_from_sim_response = not_req_from_simulator(request)
    if not_from_sim_response
      return not_from_sim_response
    end

    latest = params[:latest]
    user_id = DatabaseHelper.get_user_id(params[:username])

    request_payload = JSON.parse(request.body.read) rescue {}
    no = request_payload["content"]&.strip


    followers = DatabaseHelper.get_followees_username(user_id, no ? no.to_i : 100) #if no was not set default to 100
    follower_names = followers.map { |e| e["username"] }
    followers_response = {"follows": follower_names}
    followers_response.to_json
  end

  post '/api/fllws/:username' do
    update_latest(request)
    content_type :json
    
    not_from_sim_response = not_req_from_simulator(request)
    if not_from_sim_response
      return not_from_sim_response
    end

    user_id = DatabaseHelper.get_user_id(params[:username])
    if user_id.nil?
      halt 404
    end

    request_payload = JSON.parse(request.body.read) rescue {}

    if request_payload.key?("follow") 
      fllw_id = DatabaseHelper.get_user_id(request_payload["follow"]&.strip)
      if fllw_id.nil?
        halt 404
      end
      DatabaseHelper.follow(user_id, fllw_id)
    elsif request_payload.key?("unfollow")
      fllw_id = DatabaseHelper.get_user_id(request_payload["unfollow"]&.strip)
      if fllw_id.nil?
        halt 404
      end
      DatabaseHelper.unfollow(user_id,  fllw_id)
    end

    status 204
  end
end
