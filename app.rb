require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative 'lib/model.rb'

db = SQLite3::Database.new("db/database.db")

get('/')  do
  slim(:start)
end 

# User

get('/register') do 
  slim(:"users/register")
end

post('/register') do 
  username, password_plain = params[:username], params[:password]
  password_digest = BCrypt::Password.create(password_plain)
  db.execute("INSERT INTO users (username, password_digest) VALUES (?, ?)", username, password_digest)
  redirect("/login")
end

get('/login') do 
  slim(:"users/login")
end

post('/login') do 
  # TO DO
  redirect("/login")
end

# Albums

get('/albums') do
  @start_year = params["start-year"].nil? ? "1900" : params["start-year"]
  @end_year = params["end-year"].nil? ? "2023" : params["end-year"]
  @selected_genres = params["genres"]
  
  @albums = get_filtered_albums(@start_year, @end_year, @selected_genres)
  @genres = get_all("genres")

  slim(:"albums/index")
end

get('/albums/new') do
  db.results_as_hash = true
  @artists = get_all("artists")
  @genres = get_all("genres")
  slim(:"albums/new")
end

post('/albums') do
  title, artist, year, genres = params[:title], params[:artist], params[:year], params[:genres]
  db.execute("INSERT INTO albums (title, artist_id, year) VALUES (?, ?, ?)", title, artist, year)
  album_id = db.last_insert_row_id
  genres_formatted = genres.map { |genre| "(#{album_id}, #{genre})" }.join(", ")
  db.execute("INSERT INTO album_genre_rel (album_id, genre_id) VALUES #{genres_formatted}")
  redirect("/albums/new")
end

get('/albums/:id') do
  id = params[:id].to_i
  db.results_as_hash = true
  @album = db.execute("SELECT * FROM albums INNER JOIN artists ON albums.artist_id = artists.id WHERE albums.id = ?", id ).first
  @genres = db.execute("SELECT id, name FROM album_genre_rel INNER JOIN genres ON album_genre_rel.genre_id = genres.id WHERE album_genre_rel.album_id = ?", id)
  slim(:"albums/show")
end

#Artists

get('/artists/new') do
  slim(:"artists/new")
end

post('/artists') do
  name = params[:name]
  db.execute("INSERT INTO artists (name) VALUES (?)", name)
  redirect("/artists/new")
end

get('/artists/:id') do
  id = params[:id].to_i
  db.results_as_hash = true
  @artist = db.execute("SELECT * FROM artists WHERE id = ?", id).first
  @albums = db.execute("SELECT * FROM albums WHERE artist_id = ?", id)
  album_ids = @albums.map { |album| album["id"] }.join(", ")
  @genres = db.execute("SELECT id, name FROM album_genre_rel INNER JOIN genres ON album_genre_rel.genre_id = genres.id WHERE album_genre_rel.album_id IN (#{album_ids})")
  slim(:"artists/show")
end

# Genres

get('/genres/new') do
  slim(:"genres/new")
end

post('/genres') do
  name = params[:name]
  db.execute("INSERT INTO genres (name) VALUES (?)", name)
  redirect("/genres/new")
end