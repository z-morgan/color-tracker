require 'sinatra'

unless ENV["RACK_ENV"] == "production"
  set :server, ['webrick', 'puma']
  set :port, 4000
end

require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'bcrypt'
require 'pry' # delete this before deployment

require_relative 'yamldb'

configure do
  enable :sessions
  set :session_secret, "secret" # this should be some random value if actually deploying app
  set :erb, :escape_html => true
end

####### Application and Route helper methods #######

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

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
  verify_signed_in unless request.path_info =~ /(signin|register)/
  @db = init_db # this method is provided by whatever data storage library is required. 
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
    session[:msg] = "Welcome back #{@db.user_first_name}!"
    redirect '/inventories'
  else
    erb :signin
  end
end

post '/signin' do
  username = params[:username]
  if @db.user_exists?(username)

    if authentic_password?(@db.user_password)
      session[:username] = username
      session[:msg] = "Hello #{@db.user_first_name}!"
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
  session[:msg] = "#{@db.user_first_name} has signed out. See you soon!"
  session.delete(:username)
  redirect '/signin'
end

get '/register' do
  erb :register
end

post '/register' do
  if valid_password?
    @db.create_user(params[:username], params[:password], params[:name])
    session[:msg] = "Account created! You may now sign in."
    redirect '/signin'
  else
    session[:msg] = "It looks like your passwords don't match. *cry*"
    status 422
    erb :register
  end
end

get '/inventories' do
  @inventories = @db.user_inventories
  @name = @db.user_first_name
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

  @db.create_new_inventory(name)
  session[:msg] = "Inventory Added."
  redirect '/inventories'
end

get '/inventories/:inv_name' do
  @inventory = @db.retrieve_inventory(params[:inv_name])
  @lines = @db.retrieve_lines(params[:inv_name])
  @colors = @db.retrieve_colors(params[:inv_name])

  sort_inventory(@colors)
  erb :inventory
end

get '/inventories/:inv_name/new-line' do
  @inventory = @db.retrieve_inventory(params[:inv_name])
  erb :new_line
end

post '/inventories/:inv_name/new-line' do
  @inventory = @db.retrieve_inventory(params[:inv_name])
  new_line = params[:line]
  if invalid_object_name?(new_line)
    session[:msg] = "The name can only have letters, numbers, "\
    "spaces, dashes, periods, and apostrophies."
    halt 422, (erb :new_line)
  elsif @db.duplicate_line?(new_line, params[:inv_name])
    session[:msg] = "That line already exists!"
    halt 422, (erb :new_line)
  end

  @db.add_new_color_line(new_line, params[:inv_name])
  session[:msg] = "Color line added."
  redirect "/inventories/#{params[:inv_name].gsub(' ', '%20')}"
end

get '/inventories/:inv_name/add' do
  @inventory = @db.retrieve_inventory(params[:inv_name])
  @lines = @db.retrieve_lines(params[:inv_name])
  @colors = @db.retrieve_colors(params[:inv_name])

  if @db.no_lines?(params[:inv_name])
    session[:msg] = "You need to add a color line first."
    redirect "/inventories/#{params[:inv_name].gsub(' ', '%20')}"
  else
    sort_inventory(@db.retrieve_colors(params[:inv_name]))
    erb :add_item
  end
end

post '/inventories/:inv_name/add' do
  @inventory = @db.retrieve_inventory(params[:inv_name])
  @lines = @db.retrieve_lines(params[:inv_name])
  @colors = @db.retrieve_colors(params[:inv_name])

  validate_color_inputs
  @db.add_color(params[:line], params[:depth], params[:tone], params[:count], params[:inv_name])
  sort_inventory(@db.retrieve_colors(params[:inv_name]))

  session[:msg] = "Color product added."
  erb :add_item
end

post "/inventories/:inv_name/use" do
  @db.use_color(params[:inv_name], *(params[:color].split("_")))

  session[:msg] = "Color product used"
  redirect "/inventories/#{params[:inv_name].gsub(' ', '%20')}" 
end

####### Application Class Definitions #######

class Inventory
  attr_accessor :stocked_items, :name, :lines

  def initialize(name)
    @name = name
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
end

### YamlDB library ###

def init_db
  username = session[:username]
  username = "candidate_user" if username.nil?
  if Dir.glob(File.join(data_path, username) + ".yml").empty?
    username = "candidate_user"
  end

  YamlDB.new(username)
end

class YamlDB
  def initialize(username)
    @user = retrieve_user("#{username}.yml")
  end

  def user_password
    @user.password
  end

  def user_exists?(username)
    unless Dir.glob(File.join(data_path, username) + ".yml").empty?
      @user = retrieve_user("#{username}.yml")
    end

    @user.username == username
  end

  def user_first_name
    @user.name
  end

  def user_inventories
    @user.inventories
  end

  def create_new_inventory(name)
    @user.inventories[name] = Inventory.new(name)
    save_user_to_yaml(@user)
  end

  def duplicate_line?(name, inv_name)
    retrieve_lines(inv_name).include?(name)
  end

  def add_new_color_line(name, inv_name)
    retrieve_lines(inv_name) << name
    save_user_to_yaml(@user)
  end

  def add_color(line, depth, tone, count, inv_name)
    retrieve_inventory(inv_name).add_color(line, depth, tone, count)
    save_user_to_yaml(@user)
  end

  def use_color(inv_name, line, depth, tone)
    inventory = retrieve_inventory(inv_name)
    inventory.use_color(line, depth, tone)
    save_user_to_yaml(@user)
  end

  def no_lines?(inv_name)
    retrieve_lines(inv_name).empty?
  end

  def retrieve_inventory(inv_name)
    @user.inventories[inv_name]
  end

  def retrieve_lines(inv_name)
    @user.inventories[inv_name].lines
  end

  def retrieve_colors(inv_name)
    @user.inventories[inv_name].stocked_items
  end

  def create_user(username, password, name)
    unless ENV["RACK_ENV"] == "test"
      password = BCrypt::Password.create(password)
    end
  
    user = User.new(username, password, name)
    save_user_to_yaml(user)
  end

  private

  def save_user_to_yaml(user)
    basename = "#{user.username}.yml"
    path = File.join(data_path, basename)
    File.open(path, "w") { |f| f.write(user.to_yaml) }
  end

  def setup_inventory_objects(inv_name)
    @inventory = @user.inventories[inv_name]
    @lines = @inventory.lines
    @colors = @inventory.stocked_items
  end

  def retrieve_user(user)
    path = File.join(data_path, user)
    YAML.load_file(path, fallback: User.new("candidate_user", nil, nil))
  end
end