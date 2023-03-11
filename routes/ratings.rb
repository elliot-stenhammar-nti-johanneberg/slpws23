include Database
post('/ratings') do
    album_id, rating = params[:album_id], params[:rating]
    add_rating(session[:user]['id'], album_id, rating)
    redirect("/albums/#{album_id}")
end 

post('/ratings/:id/update') do
    id, rating, album_id = params[:id], params[:rating], params[:album_id]
    update_rating(id, rating)
    redirect("/albums/#{album_id}")
end