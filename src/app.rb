require 'sinatra/base'
require 'sequel'
require 'securerandom'
require 'digest'
require 'rack/utils'
require 'prometheus/client'
require 'prometheus/middleware/exporter'
require 'prometheus/middleware/collector'

# Helpers & DB
require_relative 'helpers/auth_helper'
require_relative 'helpers/view_helper'
require_relative 'helpers/db_helper'
require_relative 'helpers/metrics_helper'
require_relative 'db/sequel'

# Controllers
require_relative 'controllers/auth_controller'
require_relative 'controllers/timeline_controller'
require_relative 'controllers/API_controller'

class MiniTwit < Sinatra::Base
  use MetricsHelper
  use Prometheus::Middleware::Collector
  use Prometheus::Middleware::Exporter, path: '/metrics'
  use Rack::Static, urls: ["/style.css", "/js", "/images"], root: File.expand_path('public', __dir__)


  # App Config
  configure do
    set :environment, :production  # Optional: control environment-specific behavior
    set :protection, allowed_hosts: ["localhost", "127.0.0.1", "minitwit", "app"]
    set :public_folder, File.expand_path('public', __dir__)
    set :views, File.join(root, 'views')
    enable :static
    enable :sessions
    set :session_secret, ENV["SESSION_SECRET"] || SecureRandom.hex(64)
  end

  # Include helper modules
  helpers AuthHelper
  helpers ViewHelper
  helpers DatabaseHelper

  # Route controllers
  use APIController
  use AuthController
  use TimelineController

  # Default root route (optional)
  get '/' do
    redirect '/public'
  end

  # App entry point
  run! if app_file == $0
end
