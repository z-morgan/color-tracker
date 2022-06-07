require 'sinatra'

unless ENV["RACK_ENV"] == "production"
  set :server, ['webrick', 'puma']
  set :port, 4000
end

require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'bcrypt'

require_relative 'lib/postgresdb'

configure do
  enable :sessions
  set :session_secret, "secret" # this should be some random value if actually deploying app
  set :erb, :escape_html => true
end

configure :development do
  also_reload 'lib/postgresdb.rb'
  also_reload 'public/stylesheets/app.css'
end

helpers do
  def more_pages?(page, max_pages)
    max_pages > page
  end

  def sort_indicator
    case session[:sort]
    when ["depth", "ascending"]  then %q(<div class="depth">↓</div>)
    when ["depth", "descending"] then %q(<div class="depth">↑</div>)
    when ["tone", "ascending"]   then %q(<div class="tone">↓</div>)
    when ["tone", "descending"]  then %q(<div class="tone">↑</div>)
    end
  end

  # returns an array with the names of each line in the given inventory
  def all_lines
    @db.retrieve_all_lines(@inv_name, session[:username])
  end
end

####### Application helper methods #######

def verify_signed_in
  unless session[:username]
    session[:msg] = "Please sign in first."
    redirect '/signin'
  end
end

def authentic_password?(password)
  if ENV["RACK_ENV"] == "test"
    password == params[:password]
  else
    BCrypt::Password.new(password) == params[:password]
  end
end

def valid_password?
  params[:password] && (params[:password] == params[:password2])
end

# makes the sort parameters from the current request available to routes 
# and view templates
def persist_sort_strategy
  if params[:attribute]
    session[:sort] = [params[:attribute], params[:order]]
  else
    session[:sort] = ["depth", "ascending"]
  end

  @attribute, @order = session[:sort]
end

# Establishes allowed characters for naming certain things
def invalid_object_name?(obj)
  obj == '' || obj =~ /[^a-z0-9' \-\.]/i
end

####### Routes and Filters #######

before do
  @db = init_db
  verify_signed_in unless request.path_info =~ /(signin|register)/
end

after do
  @db.disconnect
  headers["Content-Type"] = "text/html;charset=utf-8"
end

not_found do
  redirect '/inventories'
end

get '/' do
  redirect '/inventories'
end

get '/signin' do
  if session[:username]
    username = session[:username]
    session[:msg] = "Welcome back #{@db.user_first_name(username)}!"
    redirect '/inventories'
  else
    erb :signin
  end
end

post '/signin' do
  username = params[:username]
  @db.reset_demo_account if username == 'stylishowl'

  if @db.user_exists?(username)

    if authentic_password?(@db.user_password(username))
      session[:username] = username
      session[:msg] = "Hello #{@db.user_first_name(username)}!"
      redirect '/inventories'
    else
      session[:msg] = "Wrong username or password"
    end

  else
    session[:msg] = "That username does not exist"
  end

  status 422
  erb :signin
end

post '/signout' do
  username = session[:username]
  session[:msg] = "#{@db.user_first_name(username)} has signed out. See you soon!"
  session.delete(:username)
  redirect '/signin'
end

get '/register' do
  erb :register
end

post '/register' do
  if !@db.user_exists?(params[:username])

    if valid_password?
      @db.create_user(params[:username], params[:password], params[:name])
      session[:msg] = "Account created! You may now sign in."
      redirect '/signin'
    else
      session[:msg] = "It looks like your passwords don't match."
    end

  else
    session[:msg] = "That username is already taken."
  end 

  status 422
  erb :register
end

get '/inventories' do
  username = session[:username]
  @inventories = @db.user_inventories(username)
  @first_name = @db.user_first_name(username)
  erb :inventory_list
end

get '/inventories/new' do
  erb :new_inventory
end

post '/inventories/new' do
  inv_name = params[:new_inventory]
  if invalid_object_name?(inv_name)
    session[:msg] = "The name can only have letters, numbers, spaces, dashes, periods, and apostrophies."
    halt 422, (erb :new_inventory)
  end

  @db.create_new_inventory(inv_name, session[:username])
  session[:msg] = "Inventory Added."
  redirect '/inventories'
end

get '/inventories/:inv_name' do
  @inv_name = params[:inv_name]
  username = session[:username]
  persist_sort_strategy

  params[:inv_page] ||= 1
  @inv_page = params[:inv_page].to_i
  @max_inv_pages = @db.count_inv_pages(@inv_name, username)
  @line_name = @db.retrieve_line_name(@inv_name, username, @inv_page)
  
  params[:line_page] ||= 1
  @line_page = params[:line_page].to_i
  @max_line_pages = @db.count_line_pages(@inv_name, username, @line_name)
  @colors = @db.retrieve_colors(@inv_name, username, @line_name, @line_page, session[:sort])

  erb :inventory
end

get '/inventories/:inv_name/new-line' do
  @inv_name = params[:inv_name]
  erb :new_line
end

post '/inventories/:inv_name/new-line' do
  @inv_name = params[:inv_name]
  new_line = params[:line]
  if invalid_object_name?(new_line)
    session[:msg] = "The name can only have letters, numbers, "\
    "spaces, dashes, periods, and apostrophies."
    halt 422, (erb :new_line)
  elsif @db.line_exists_in_inventory?(new_line, params[:inv_name], session[:username])
    session[:msg] = "That line already exists!"
    halt 422, (erb :new_line)
  end

  @db.add_new_color_line(new_line, params[:inv_name], session[:username])
  session[:msg] = "Color line added."
  redirect "/inventories/#{params[:inv_name].gsub(' ', '%20')}"
end

get '/inventories/:inv_name/add' do
  @inv_name = params[:inv_name]
  username = session[:username]
  persist_sort_strategy

  params[:inv_page] ||= 1
  @inv_page = params[:inv_page].to_i
  @max_inv_pages = @db.count_inv_pages(@inv_name, username)
  @line_name = @db.retrieve_line_name(@inv_name, username, @inv_page)

  if @db.no_lines?(@inv_name, username)
    session[:msg] = "You need to add a color line first."
    redirect "/inventories/#{@inv_name.gsub(' ', '%20')}"
  else
    params[:line_page] ||= 1
    @line_page = params[:line_page].to_i
    @max_line_pages = @db.count_line_pages(@inv_name, username, @line_name)
    @colors = @db.retrieve_colors(@inv_name, username, @line_name, @line_page, session[:sort])
    erb :add_item
  end
end

post '/inventories/:inv_name/add' do
  @inv_name = params[:inv_name]
  username = session[:username]
  persist_sort_strategy

  params[:inv_page] ||= 1
  @inv_page = params[:inv_page].to_i
  @max_inv_pages = @db.count_inv_pages(@inv_name, username)
  @line_name = @db.retrieve_line_name(@inv_name, username, @inv_page)

  @db.add_color(params[:line], params[:depth], params[:tone], params[:count], @inv_name, username)

  params[:line_page] ||= 1
  @line_page = params[:line_page].to_i
  @max_line_pages = @db.count_line_pages(@inv_name, username, @line_name[0])
  @colors = @db.retrieve_colors(@inv_name, username, @line_name, @line_page, session[:sort])

  session[:msg] = "Color product added."
  erb :add_item
end

post "/inventories/:inv_name/use" do
  @db.use_color(session[:username], params[:inv_name], *(params[:color].split("_")))

  session[:msg] = "Color product used"
  redirect "/inventories/#{params[:inv_name].gsub(' ', '%20')}" 
end
