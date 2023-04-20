# Display register form
get('/register') do 
    @password_mismatch = params[:password_mismatch].nil? ? false : params[:password_mismatch]
    slim(:"users/register")
end

# Add user
#
# @param :username [String] Username
# @param :password [String] Password
# @param :password_repeat [String] Repeated password
post('/register') do 
  username, password, password_repeat = params[:username], params[:password], params[:password_repeat]
  if password != password_repeat
    redirect(("/register?password_mismatch=true"))
  end
  password_digest = BCrypt::Password.create(password)
  add_user(username, password_digest)
  redirect("/login")
end

# Display login form
#
# @param :failed [Boolean] Login failed  
get('/login') do 
  @failed = params[:failed]
  slim(:"users/login")
end

# Login user
#
# @param :username [String] Username  
# @param :password [String] Password  
post('/login') do 
  username, password = params[:username], params[:password]
  user = get_user_by_username(username) 
  if !user.nil?
    if BCrypt::Password.new(user["password_digest"]) == password
      session[:user] = user
      redirect("/albums")
    end
  end
  redirect("/login?failed=true")
end

# Logout user
post('/logout') do
  session.clear()
  redirect("/")
end

get('/profile') do
  if logged_in?()
    @ratings = get_ratings_by_user_id(session[:user]["id"])
    slim(:"users/show")
  else 
    redirect("/")
  end
end

get('/users/edit') do
  if logged_in?()
    slim(:"users/edit")
  else 
    redirect("/")
  end
end

#Update user
post('/users/edit') do
  username, password = params[:username], params[:password]
  update_user(username, password)
  session[:user]["username"] = username
  redirect("/")
end