# Display list of genres
get('/genres') do
  @genres = get_all_genres()
  slim(:"genres/index")
end

# Display new genre form
get('/genres/new') do
  if_permission_not(1) { redirect("/") } 
  @genres = get_all_genres()
  slim(:"genres/new")
end

# Add genre
#
# @param :name [String] Genre name
# @param :parent_genre_id [Integer] Parent genre ID
post('/genres') do
  if_permission_not(1) { redirect("/") }
  
  name, parent_genre_id = params[:name], params[:parent_genre_id] 
  add_genre(name, parent_genre_id)
  redirect("/genres/new")
end