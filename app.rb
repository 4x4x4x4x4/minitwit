require 'sinatra/base'
require_relative 'controllers/auth_controller'
require_relative 'controllers/timeline_controller'
require_relative 'controllers/API_controller'
require_relative 'helpers/auth_helper'
require_relative 'helpers/view_helper'

class MiniTwit < Sinatra::Base
  # very important that this is loaded first 
  use Rack::Static, urls: ["/style.css"], root: File.expand_path('public', __dir__)

  helpers AuthHelper
  helpers ViewHelper

  use APIController
  use AuthController
  use TimelineController

  get '/' do
    redirect '/public'
  end

  run! if app_file == $0
end
