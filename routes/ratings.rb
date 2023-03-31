# Add rating
#
# @param :album_id [Integer] Album ID
# @param :rating [Integer] Rating value
post('/ratings') do
    album_id, rating = params[:album_id], params[:rating]
    add_rating(session[:user]['id'], album_id, rating)
    redirect("/albums/#{album_id}")
end 

# Update rating
#
# @param :id [Integer] Rating ID
# @param :rating [Integer] New rating value
# @param :album_id [Integer] Album ID
post('/ratings/:id/update') do
    id, rating, album_id = params[:id], params[:rating], params[:album_id]
    update_rating(id, rating)
    redirect("/albums/#{album_id}")
end