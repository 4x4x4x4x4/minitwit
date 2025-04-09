require 'sinatra/base'
require_relative '../helpers/auth_helper'

class AuthController < Sinatra::Base
  enable :sessions
  set :views, File.expand_path('../../views', __FILE__)
  helpers AuthHelper

  # Login
  get '/login' do
    erb :login
  end

  post '/login' do
    user_id = DatabaseHelper.get_user_id(params[:username])

    if user_id && DatabaseHelper.check_user_password(user_id, params[:password])
      session[:user_id] = user_id
      session[:success_message] = "You were logged in"
      redirect '/'
    else
      session[:error_message] = user_id ? "Invalid password" : "Invalid username"
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
      session[:error_message] = "The two passwords do not match"
      return erb :register
    end

    if params[:username].nil? || params[:username].empty?
      session[:error_message] = "You have to enter a username"
      return erb :register
    end  
  
    if params[:email].nil? || params[:email].empty?
      session[:error_message] = "You have to enter an email address"
      return erb :register
    end

    validate_email = valid_email(params[:email])
    if !validate_email
      session[:error_message] = "You have to enter a valid email address"
      return erb :register
    end
  
    if params[:password].nil? || params[:password].empty?
      session[:error_message] = "You have to enter a password"
      return erb :register
    end
  
    existing_user = DatabaseHelper.get_user_id(params[:username])
    if existing_user
      session[:error_message] = "The username is already taken"
      return erb :register
    end
  
    begin
      DatabaseHelper.new_user(params[:username], params[:email], params[:password])
    
      session[:success_message] = "You were successfully registered and can login now"           
      redirect '/login'
    rescue SQLite3::Exception => e
      halt 500, { error: "Database error: #{e.message}" }.to_json
    end
  end

  # Logout
  get '/logout' do
    session.clear
    session[:success_message] = "You were logged out"
    redirect '/public'
  end
end
