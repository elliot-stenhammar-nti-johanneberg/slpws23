# Display (filtered) list of albums 
# 
# @param start-year [Integer] Start year
# @param end-year [Integer] End year
# @param selected-genres [Array<Integer>] Array of genre ids
# @param sort [String] Sort type ("top" or "popular")
get('/albums') do
  @start_year = params["start-year"].nil? ? "1900" : params["start-year"]
  @end_year = params["end-year"].nil? ? "2023" : params["end-year"]
  @selected_genres = params["genres"]
  @sort = params["sort"].nil? ? "top" : params["sort"]
  
  @albums = get_filtered_albums(@start_year, @end_year, @selected_genres, @sort)
  @genres = get_all("genres")
  slim(:"albums/index")
end

# Display new album form 
get('/albums/new') do
  if_permission_not(1) { redirect("/albums") }
  @artists = get_all("artists")
  @genres = get_all("genres")
  slim(:"albums/new")
end

# Add new album 
# 
# @param :title [String] Album title
# @param :artist [String] Album's artist
# @param :year [Integer] Year published
# @param :genres [Array<Integer>] Array of genre ids
post('/albums') do
  title, artist, year, genres = params[:title], params[:artist], params[:year], params[:genres]
  add_album(title, artist, year, genres)
  redirect("/albums/new")
end

# Display album info
# 
# @param :id [Integer] Album ID
get('/albums/:id') do
  id = params[:id].to_i
  @album = get_album(id)
  @genres = get_album_genres(id)
  @album_rating = get_album_rating_avg(id)
  if !session[:user].nil?
    @user_rating = get_user_album_rating(session[:user]["id"], id)
  end
  slim(:"albums/show")
end

# Display edit album form 
# 
# @param :id [Integer] Album ID
get('/albums/:id/edit') do
  id = params[:id].to_i
  if_permission_not(1) { redirect("/albums/#{id}") }

  @album = get_album(id)
  @artists = get_all("artists")
  @genres = get_all("genres")
  @album_genres = get_album_genres(id)
  slim(:"albums/edit")
end

# Delete album
# 
# @param :id [Integer] Album ID
post('/albums/:id/delete') do
  if_permission_not(1) { redirect("/") }

  id = params[:id]
  delete_album(id)
  redirect("/albums")
end

# Update album info
# 
# @param :id [Integer] Album ID
# @param :title [String] Album title
# @param :artist [String] Album's artist
# @param :year [Integer] Year published
# @param :genres [Array<Integer>] Array of genre ids
post('/albums/:id/update') do
  if_permission_not(1) { redirect("/") }
  
  id, title, artist, year, genres = params[:id], params[:title], params[:artist], params[:year], params[:genres]
  update_album(id, title, artist, year, genres)
  redirect("/albums/#{id}")
end
