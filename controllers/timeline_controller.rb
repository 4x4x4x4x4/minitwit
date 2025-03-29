require 'sinatra/base'
require 'sqlite3'
require_relative '../helpers/auth_helper'
require_relative '../helpers/view_helper'

class TimelineController < Sinatra::Base
  helpers AuthHelper
  helpers ViewHelper

  set :views, File.expand_path('../../views', __FILE__)

  # Home / Timeline
  get '/' do
    redirect '/public' unless logged_in?

    @messages = DatabaseHelper.get_user_timeline(session[:user_id],30)

    erb :timeline
  end

  # Public Timeline
  get '/public' do
    @messages = DatabaseHelper.get_messages(30)
    erb :timeline #change view to use :email instead of 'email'
  end

  # Add a new message
  post '/add_message' do
    halt 401 unless logged_in?

    if params[:text] && !params[:text].empty?
      DatabaseHelper.new_message(session[:user_id], params[:text])
      session[:success_message] = "Your message was recorded"
    end    
    redirect '/'
  end

  # User Timeline
  get '/:username' do
    @profile_user = DatabaseHelper.get_user(DatabaseHelper.get_user_id(params[:username]))
    halt 404 unless @profile_user

    @messages = DatabaseHelper.get_user_messages(@profile_user.user_id,30)

    @followed = false
    if logged_in?
      @followed = DatabaseHelper.follows(session[:user_id], @profile_user.user_id)
    end

    erb :timeline
  end

  # Follow a user
  get '/:username/follow' do
    halt 401 unless logged_in?

    whom_id = DatabaseHelper.get_user_id([params[:username]])
    halt 404 unless whom_id

    DatabaseHelper.follow(session[:user_id], whom_id)
    session[:success_message] = "You are now following &#34;#{params[:username]}&#34;"
    redirect "/#{params[:username]}"
  end

  # Unfollow a user
  get '/:username/unfollow' do
    halt 401 unless logged_in?

    whom_id = DatabaseHelper.get_user_id([params[:username]])
    halt 404 unless whom_id

    DatabaseHelper.unfollow(session[:user_id], whom_id)
    session[:success_message] = "You are no longer following &#34;#{params[:username]}&#34;"
    redirect "/#{params[:username]}"
  end
end
