# Display new artist form
get('/artists/new') do
  if_permission_not(1) { redirect("/") }
  slim(:"artists/new")
end

# Add new artist
#
# @param :name [String] Artist name
post('/artists') do
  name = params[:name]
  add_artist(name)
  redirect("/artists/new")
end

# Display artist info
#
# @param :id [Integer] Artist ID
get('/artists/:id') do
  id = params[:id].to_i
  @artist = get_artist(id)
  @albums = get_artist_albums(id)
  @genres = get_albums_genres(@albums)
  slim(:"artists/show")
end

# Display edit artist form
#
# @param :id [Integer] Artist ID
get('/artists/:id/edit') do
  id = params[:id].to_i
  if_permission_not(1) { redirect("/artists/#{id}") }
  
  @artist = get_artist(id)
  slim(:"artists/edit")
end

# Delete artist
#
# @param :id [Integer] Artist ID
post('/artists/:id/delete') do
  id = params[:id]
  delete_artist(id)
  redirect("/albums")
end

# Update artist info
#
# @param :id [Integer] Artist ID
# @param :name [String] Artist name
post('/artists/:id/update') do 
  id, name = params[:id].to_i, params["name"]
  update_artist(id, name)
  redirect("/artists/#{id}")
end
  