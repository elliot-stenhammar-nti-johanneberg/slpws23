include Database
get('/genres') do
  @genres = get_all_genres()
  slim(:"genres/index")
end

get('/genres/new') do
  if_permission_not(1) { redirect("/") } 
  @genres = get_all("genres")
  slim(:"genres/new")
end

post('/genres') do
  name, parent_genre_id = params[:name], params[:parent_genre_id]
  add_genre(name, parent_genre_id)
  redirect("/genres/new")
end