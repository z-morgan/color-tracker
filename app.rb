require 'sinatra'

unless ENV["RACK_ENV"] == "production"
  set :server, ['webrick', 'puma']
  set :port, 4000
end

require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'bcrypt'
require 'securerandom'

require_relative 'lib/postgresdb'
require_relative 'lib/inventory'
require_relative 'lib/color'

configure do
  enable :sessions
  set :session_secret, ENV.fetch('SESSION_SECRET') { SecureRandom.hex(64) }
  set :erb, :escape_html => true
end

configure :development do
  also_reload 'lib/postgresdb.rb'
end

COLORS_PER_PAGE = 15

### View Helper Methods ###

helpers do
  # provides an indicator based on how the page elements are sorted
  def sort_indicator
    case session[:sort]
    when ["depth", "ascending"]  then %q(<div class="depth">↓</div>)
    when ["depth", "descending"] then %q(<div class="depth">↑</div>)
    when ["tone", "ascending"]   then %q(<div class="tone">↓</div>)
    when ["tone", "descending"]  then %q(<div class="tone">↑</div>)
    end
  end

  def all_lines
    @inventory.lines.keys
  end

  def colors_by_page(colors_arr, page_num)
    idx1 = COLORS_PER_PAGE * (page_num - 1)
    idx2 = COLORS_PER_PAGE * page_num

    colors_arr[idx1...idx2]
  end

  def total_line_pages(colors_arr)
    num, remaining = colors_arr.size.divmod(COLORS_PER_PAGE)

    num += 1 if remaining > 0
    num
  end
end

### Application helper methods ###

def verify_signed_in
  return if session[:username]
  session[:msg] = "Please sign in first."
  redirect '/signin'
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

def page_number(page)
  params[page] = if params[page]
                   params[page].to_i
                 else
                   1
                 end
end

# makes the sort parameters from the current request available to routes
# and view templates
def persist_sort_strategy
  if params[:attribute]
    session[:sort] = [params[:attribute], params[:order]]
  else
    session[:sort] ||= ["depth", "ascending"]
  end

  @attribute, @order = session[:sort]
end

# Establishes allowed characters for naming certain things
def invalid_object_name?(obj)
  obj == '' || obj =~ /[^a-z0-9' \-\.]/i
end

### Routes and Filters ###

before do
  @db = init_db
  verify_signed_in unless request.path_info =~ /(signin|register)/
  persist_sort_strategy
end

before '/inventories/:inv_name*' do
  page_number(:inv_page)
  page_number(:line_page)

  @inventory = @db.retrieve_inventory(session[:username], params[:inv_name])
  @inventory.sort_colors!(session[:sort])
end

after do
  @db.disconnect
  headers["Content-Type"] = "text/html;charset=utf-8"
end

not_found do
  status 404
  erb :not_found
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
  name = @db.user_first_name(session.delete(:username))
  session[:msg] = "#{name} has signed out. See you soon!"
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
    session[:msg] = "The name can only have letters, numbers," \
    " spaces, dashes, periods, and apostrophies."
    halt 422, (erb :new_inventory)
  end

  @db.create_new_inventory(inv_name, session[:username])
  session[:msg] = "Inventory Added."
  redirect '/inventories'
end

get '/inventories/:inv_name' do
  @line_name = @inventory.lines.keys[params[:inv_page] - 1]
  erb :inventory
end

get '/inventories/:inv_name/new-line' do
  @inv_name = params[:inv_name]
  erb :new_line
end

post '/inventories/:inv_name/new-line' do
  if invalid_object_name?(params[:new_line])
    session[:msg] = "The name can only have letters, numbers, "\
    "spaces, dashes, periods, and apostrophies."
    halt 422, (erb :new_line)
  elsif @inventory.lines.keys.include?(params[:new_line])
    session[:msg] = "That line already exists!"
    halt 422, (erb :new_line)
  end

  @db.add_new_color_line(params[:new_line],
                         params[:inv_name], session[:username])
  session[:msg] = "Color line added."
  redirect "/inventories/#{params[:inv_name].gsub(' ', '%20')}"
end

get '/inventories/:inv_name/add' do
  if @inventory.lines.empty?
    session[:msg] = "You need to add a color line first."
    redirect "/inventories/#{params[:inv_name].gsub(' ', '%20')}"
  else
    @line_name = @inventory.lines.keys[params[:inv_page] - 1]
    @add_item_form = true
    erb :inventory
  end
end

post '/inventories/:inv_name/add' do
  color_details = [
    params[:line],
    params[:depth],
    params[:tone],
    params[:count],
    params[:inv_name],
    session[:username]
  ]

  @db.add_color(*color_details)

  @inventory = @db.retrieve_inventory(session[:username], params[:inv_name])
  @inventory.sort_colors!(session[:sort])

  @line_name = @inventory.lines.keys[params[:inv_page] - 1]

  session[:msg] = "Color product added."
  redirect "/inventories/#{params[:inv_name].gsub(' ', '%20')}/add"
end

post "/inventories/:inv_name/use" do
  @db.use_color(session[:username],
                params[:inv_name], *(params[:color].split("_")))

  session[:msg] = "Color product used"
  redirect "/inventories/#{params[:inv_name].gsub(' ', '%20')}"
end
