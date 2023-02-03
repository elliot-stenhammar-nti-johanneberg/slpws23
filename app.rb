require 'sinatra'
require 'slim'
require 'sqlite3'

db = SQLite3::Database.new("db/database.db")

get('/')  do
  slim(:start)
end 

get('/albums') do

end

get('/artists') do

end

get('/albums/new') do
    db.results_as_hash = true
    artists = db.execute("SELECT * FROM artists")
    genres = db.execute("SELECT * FROM genres")
    slim(:"albums/new", locals:{genres:genres, artists:artists})
end

get('/artist/new') do
    slim(:"artist/new")
end

post('/albums') do

end

post('/artists') do

end

get('/albums/:id') do

end

get('/artist/:id') do

end

post('/albums/:id/delete') do

end

post('/artist/:id/delete') do

end

get('/albums/:id/edit') do
  
end

get('/artist/:id/edit') do
  
end

post('/albums/:id/update') do

end

post('/artist/:id/update') do

end