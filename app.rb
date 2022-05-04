require 'sinatra'
set :server, ['webrick', 'puma']
set :port, 4000
require 'sinatra/reloader'
require 'tilt/erubis'
require 'yaml'
require 'bcrypt'

configure do
  enable :sessions
  set :session_secret, "secret" # this should be some random value if actually deploying app
  set :erb, :escape_html => true
end

####### Route helper methods #######

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

def retrieve_user(user)
  path = File.join(data_path, user)
  YAML.load_file(path)
end

def save_user_to_yaml(user)
  yaml_db_name = "#{user.username}.yml"
  path = File.join(data_path, yaml_db_name)
  File.open(path, "w") { |f| f.write(user.to_yaml) }
end

def verify_signed_in
  unless session[:username]
    session[:msg] = "Please sign in first."
    redirect '/signin'
  end
end

def authentic_password?
  if ENV["RACK_ENV"] == "test"
    @user.password == params[:password]
  else
    BCrypt::Password.new(@user.password) == params[:password]
  end
end

def valid_password?
  params[:password] && (params[:password] == params[:password2])
end

def create_user
  if ENV["RACK_ENV"] == "test"
    password = params[:password]
  else
    password = BCrypt::Password.create(params[:password])
  end

  user = User.new(params[:username], password, params[:name])
  save_user_to_yaml(user)
end

def persist_sort_strategy
  if params[:attribute]
    session[:sort] = [params[:attribute], params[:order]]
  else
    session[:sort] = ["depth", "ascending"]
  end

  @attribute, @order = session[:sort]
end

def sort_by_depth!(colors_arr)
  colors_arr.sort_by! { |color| color.depth.to_i }
end

def sort_inventory(colors_arr)
  persist_sort_strategy
  case session[:sort]
  when ["depth", "ascending"]
    sort_by_depth!(colors_arr)
    @indicator = %q(<div class="depth">↓</div>)
  when ["depth", "descending"]
    sort_by_depth!(colors_arr).reverse!
    @indicator = %q(<div class="depth">↑</div>)
  when ["tone", "ascending"]
    colors_arr.sort_by!(&:tone)
    @indicator = %q(<div class="tone">↓</div>)
  when ["tone", "descending"]
    colors_arr.sort_by!(&:tone).reverse!
    @indicator = %q(<div class="tone">↑</div>)
  end
end

def setup_inventory_objects
  @inventory = @user.inventories[params[:inv_name]]
  @lines = @inventory.lines
  @colors = @inventory.stocked_items
end

def validate_color_inputs
  if params[:line] == "" || params[:depth] == "" || params[:tone] == "" || params[:count] == ""

    session[:invalid_color] = "At least one field was blank. Color product not added."
    redirect "/inventories/#{params[:inv_name].gsub(' ', '%20')}/add"
  end
end

def invalid_object_name?(obj)
  obj == '' || obj =~ /[^a-z0-9' \-\.]/i
end

####### Routes and Filters #######

before do
  unless request.path_info =~ /(signin|register)/
    verify_signed_in
    @user = retrieve_user("#{session[:username]}.yml")
  end
end

after do
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
    session[:msg] = "Welcome back #{session[:name]}!"
    redirect '/inventories'
  else

    erb :signin
  end
end

post '/signin' do
  username = params[:username]
  if File.exist?("#{data_path}/#{username}.yml")
    @user = retrieve_user("#{username}.yml")

    if @user.username == username && authentic_password?
      session[:username] = username
      session[:name] = @user.name
      session[:msg] = "Hello #{@user.name}!"
      redirect '/inventories'
    end

    session[:msg] = "Wrong username or password"
  else
    session[:msg] = "That username does not exist"
  end

  status 422
  erb :signin
end

post '/signout' do
  session[:msg] = "#{session.delete(:name)} has signed out. See you soon!"
  session.delete(:username)
  redirect '/signin'
end

get '/register' do
  erb :register
end

post '/register' do
  if valid_password?
    create_user
    session[:msg] = "Account created! You may now sign in."
    redirect '/signin'
  else
    session[:msg] = "It looks like your passwords don't match. *cry*"
    status 422

    erb :register
  end
end

get '/inventories' do
  @inventories = @user.inventories
  erb :inventory_list
end

get '/inventories/new' do
  erb :new_inventory
end

post '/inventories/new' do
  name = params[:new_inventory]
  if invalid_object_name?(name)
    session[:msg] = "The name can only have letters, numbers, spaces, dashes, periods, and apostrophies."
    halt 422, (erb :new_inventory)
  end
  
  @user.inventories[name] = Inventory.new(name, @user.name)
  save_user_to_yaml(@user)

  session[:msg] = "Inventory Added."
  redirect '/inventories'
end

get '/inventories/:inv_name' do 
  setup_inventory_objects
  sort_inventory(@colors)

  erb :inventory
end

get '/inventories/:inv_name/new-line' do
  setup_inventory_objects
  erb :new_line
end

post '/inventories/:inv_name/new-line' do
  setup_inventory_objects
  new_line = params[:line]
  if invalid_object_name?(new_line)
    session[:msg] = "The name can only have letters, numbers, "\
    "spaces, dashes, periods, and apostrophies."
    halt 422, (erb :new_line)
  elsif @lines.include?(new_line)
    session[:msg] = "That line already exists!"
    halt 422, (erb :new_line)
  end

  @lines << new_line
  save_user_to_yaml(@user)

  session[:msg] = "Color line added."
  redirect "/inventories/#{params[:inv_name].gsub(' ', '%20')}"
end

get '/inventories/:inv_name/add' do
  setup_inventory_objects
  if @lines.empty?
    session[:msg] = "You need to add a color line first."
    redirect "/inventories/#{params[:inv_name].gsub(' ', '%20')}"
  else
    sort_inventory(@colors)
    erb :add_item
  end
end

post '/inventories/:inv_name/add' do
  setup_inventory_objects
  validate_color_inputs
  @inventory.add_color(params[:line], params[:depth], params[:tone], params[:count])
  save_user_to_yaml(@user)
  sort_inventory(@colors)

  session[:msg] = "Color product added."
  erb :add_item
end

post "/inventories/:inv_name/use" do
  setup_inventory_objects
  @inventory.use_color(*(params[:color].split("_")))
  save_user_to_yaml(@user)

  session[:msg] = "Color product used"
  redirect "/inventories/#{params[:inv_name].gsub(' ', '%20')}" 
end

####### Application Class Definitions #######

class Inventory
  attr_accessor :stocked_items, :name, :lines

  def initialize(name, owner)
    @name = name
    @owner = owner
    @lines = []
    @stocked_items = []
  end

  def add_color(line, depth, tone, count)
    color = color_stocked?(line, depth, tone)
    if color
      total = color.count.to_i + count.to_i
      color.count = total
    else
      add_new_color(line, depth, tone, count)
    end
  end

  def use_color(line, depth, tone)
    color = color_stocked?(line, depth, tone)
    total = color.count.to_i - 1

    if total <= 0
      @stocked_items.delete_if do |color|
        color.line == line && color.depth == depth && color.tone == tone
      end
    else
      color.count = total.to_s
    end
  end

  private

  def color_stocked?(line, depth, tone)
    @stocked_items.find do |color|
      color.line == line && color.depth == depth && color.tone == tone
    end
  end

  def add_new_color(line, depth, tone, count)
    stocked_items << Color.new(line, depth, tone, count)
  end
end

class Color
  attr_accessor :line, :depth, :tone, :count

  def initialize(line, depth, tone, count)
    @line = line
    @depth = depth
    @tone = tone
    @count = count
  end

  def to_s
    "#{line}_#{depth}_#{tone}"
  end
end

class User
  attr_accessor :inventories, :username, :password, :name

  def initialize(username, password, name)
    @username = username
    @password = password
    @name = name
    @inventories = {}
  end

  def create_an_inventory
  end
end
