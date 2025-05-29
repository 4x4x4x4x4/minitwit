
require 'fileutils'     # os module
require 'time'          # time module
require 'sqlite3'       # sqlite3 module
require 'digest/md5'    # hashlib.md5
require 'pathname'      # pathlib.Path
require 'date'          # datetime
require 'json'          # JSON
require 'sinatra'       # Flask
require 'bcrypt'        # Equivalent to werkzeug.security password hashing

# DATABASE = "/database/minitwit.db" # Path to the database file
DATABASE = "some.db" # Path to the database file
SIM = "sim_action.txt" # Path to the sim_action file
DEBUG = true


# Delete database for testing
Pathname.new(DATABASE).delete if File.exist?(DATABASE)
Pathname.new(SIM).delete if File.exist?(SIM)

init_db

# Create a basic Sinatra application
set :root, File.dirname(__FILE__)  # Set the root path for the app

# Configuration (equivalent to Flask's app.config.from_object)
configure do
  set :app_secret, 'your_secret_key'
  set :environment, :development
end
