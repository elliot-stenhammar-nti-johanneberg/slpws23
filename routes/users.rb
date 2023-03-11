include Database
get('/register') do 
    @password_mismatch = params[:password_mismatch].nil? ? false : params[:password_mismatch]
    slim(:"users/register")
end

post('/register') do 
  username, password, password_repeat = params[:username], params[:password], params[:password_repeat]
  # Check if username is taken
  if password != password_repeat
    redirect(("/register?password_mismatch=true"))
  end
  password_digest = BCrypt::Password.create(password)
  add_user(username, password_digest)
  redirect("/login")
end

get('/login') do 
  @failed = params[:failed]
  slim(:"users/login")
end

post('/login') do 
  username, password= params[:username], params[:password]
  user = get_user_by_username(username) 
  if !user.nil?
    if BCrypt::Password.new(user["password_digest"]) == password
      session[:user] = user
      redirect("/albums")
    end
  end
  redirect("/login?failed=true")
end

post('/logout') do
  session.clear()
  redirect("/")
end