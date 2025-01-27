require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

require_relative 'lib/model.rb'
include Database
include Helper

require_relative 'routes/albums.rb'
require_relative 'routes/artists.rb'
require_relative 'routes/genres.rb'
require_relative 'routes/users.rb'
require_relative 'routes/ratings.rb'

enable :sessions

# Landing page
get('/')  do
  slim(:home)
end

get('/cooldown') do
  "<h1>Too many login attemps</h1>"
end