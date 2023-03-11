include Database

get('/albums') do
  @start_year = params["start-year"].nil? ? "1900" : params["start-year"]
  @end_year = params["end-year"].nil? ? "2023" : params["end-year"]
  @selected_genres = params["genres"]
  @sort = params["sort"].nil? ? "top" : params["sort"]

  @albums = get_filtered_albums(@start_year, @end_year, @selected_genres, @sort)
  @genres = get_all("genres")
  slim(:"albums/index")
end

get('/albums/new') do
  if_permission_not(1) { redirect("/albums") }
  
  @artists = get_all("artists")
  @genres = get_all("genres")
  slim(:"albums/new")
end

post('/albums') do
  title, artist, year, genres = params[:title], params[:artist], params[:year], params[:genres]
  add_album(title, artist, year, genres)
  redirect("/albums/new")
end

get('/albums/:id') do
  id = params[:id].to_i
  @album = get_album(id)
  @genres = get_album_genres(id)
  if !session[:user].nil?
    @rating = get_user_album_rating(session[:user]["id"], id)
  end
  slim(:"albums/show")
end

get('/albums/:id/edit') do
  id = params[:id].to_i
  if_permission_not(1) { redirect("/albums/#{id}") }

  @album = get_album(id)
  @artists = get_all("artists")
  @genres = get_all("genres")
  @album_genres = get_album_genres(id)
  slim(:"albums/edit")
end

post('/albums/:id/delete') do
  id = params[:id]
  delete_album(id)
  redirect("/albums")
end

post('/albums/:id/update') do
  id, title, artist, year, genres = params[:id], params[:title], params[:artist], params[:year], params[:genres]
  update_album(id, title, artist, year, genres)
  redirect("/albums/#{id}")
end
