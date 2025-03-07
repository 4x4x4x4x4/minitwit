require 'sinatra/base'
require 'sqlite3'
require_relative '../helpers/auth_helper'
require_relative '../helpers/view_helper'

class TimelineController < Sinatra::Base
  helpers AuthHelper
  helpers ViewHelper

  set :views, File.expand_path('../../views', __FILE__)

  before do
    @db = db_connection
    @user = current_user
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
      ORDER BY message.pub_date DESC LIMIT 30",
      [session[:user_id], session[:user_id]]
    )

    erb :timeline
  end

  # Public Timeline
  get '/public' do
    @messages = @db.execute(
      "SELECT message.*, user.* FROM message 
      JOIN user ON message.author_id = user.user_id 
      WHERE message.flagged = 0 
      ORDER BY message.pub_date DESC LIMIT 30"
    )
    
    erb :timeline
  end

  # Add a new message
  post '/add_message' do
    halt 401 unless logged_in?

    if params[:text] && !params[:text].empty?
      @db.execute("INSERT INTO message (author_id, text, pub_date, flagged) VALUES (?, ?, ?, 0)", 
                  [session[:user_id], params[:text], Time.now.to_i])
      session[:success_message] = "Your message was recorded"
    end    
    redirect '/'
  end

  # User Timeline
  get '/:username' do
    @profile_user = @db.execute("SELECT * FROM user WHERE username = ?", [params[:username]]).first
    halt 404 unless @profile_user

    @messages = @db.execute(
      "SELECT message.*, user.* FROM message 
      JOIN user ON message.author_id = user.user_id 
      WHERE user.user_id = ? 
      ORDER BY message.pub_date DESC LIMIT 30", 
      [@profile_user['user_id']]
    )

    @followed = false
    if logged_in?
      result = @db.execute("SELECT 1 FROM follower WHERE who_id = ? AND whom_id = ?", 
                           [session[:user_id], @profile_user['user_id']])
      @followed = !result.empty?
    end

    erb :timeline
  end

  # Follow a user
  get '/:username/follow' do
    halt 401 unless logged_in?

    whom_id = @db.execute("SELECT user_id FROM user WHERE username = ?", [params[:username]]).first
    halt 404 unless whom_id

    @db.execute("INSERT INTO follower (who_id, whom_id) VALUES (?, ?)", [session[:user_id], whom_id['user_id']])
    session[:success_message] = "You are now following &#34;#{params[:username]}&#34;"
    redirect "/#{params[:username]}"
  end

  # Unfollow a user
  get '/:username/unfollow' do
    halt 401 unless logged_in?

    whom_id = @db.execute("SELECT user_id FROM user WHERE username = ?", [params[:username]]).first
    halt 404 unless whom_id

    @db.execute("DELETE FROM follower WHERE who_id = ? AND whom_id = ?", [session[:user_id], whom_id['user_id']])
    session[:success_message] = "You are no longer following &#34;#{params[:username]}&#34;"
    redirect "/#{params[:username]}"
  end
end
