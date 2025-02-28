require 'sinatra/base'
require 'sqlite3'
require 'bcrypt'
require_relative '../helpers/auth_helper'

class AuthController < Sinatra::Base
  enable :sessions
  helpers AuthHelper

  set :views, File.expand_path('../../views', __FILE__)

  before do
    @db = db_connection
  end

  after do
    @db.close if @db
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
  get '/t/register' do
    redirect '/' if logged_in?
    erb :register
  end

  post '/t/register' do
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

  # Logout
  get '/logout' do
    session.clear
    redirect '/public'
  end
end
