require 'sinatra'
set :server, ['webrick', 'puma']
set :port, 4000
require 'sinatra/reloader'
require 'tilt/erubis'
require 'yaml'
# require_relative 'dev_spike'


configure do
  enable :sessions
  set :session_secret, "secret" # this should be some random value if actually deploying app
end

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

### The next few methods are for dev purposes only
# def populate_inventories(user)
#   user.inventories.each do |_, inv|
#     inv.add_new_color("wella", 10, 2, 5)
#     inv.add_new_color("cosmoprof", 8, 3, 4)
#   end
# end

# # def create_dev_inventories
# #   inventories_arr = {
# #     "Zach's 1st Inventory" => Inventory.new("Zach's 1st Inventory", "zmorgan"),
# #     "Zach's 2nd inventory" => Inventory.new("Zach's 2nd inventory", "zmorgan")
# #   }
# #   populate_inventories(inventories_arr)
# #   File.open(data_path, "w") do |yml_file|
# #     yml_file.write(inventories_arr.to_yaml)
# #   end
# # end

# def create_dev_user
#   @user = User.new("zmorgan", "secret", "Zach")
#   @user.inventories["Zach's 1st Inventory"] = Inventory.new("Zach's 1st Inventory", "zmorgan")
#   @user.inventories["Zach's 2nd inventory"] = Inventory.new("Zach's 2nd inventory", "zmorgan")
#   populate_inventories(@user)
#   save_user_to_yaml(@user)
# end
### end of dev methods

def verify_signed_in
  unless session[:username]
    session[:msg] = "Please sign in first."
    redirect '/signin'
  end
end

def valid_password?
  params[:password] && params[:password] == params[:password2]
end

def create_user
  user = User.new(params[:username], params[:password], params[:name])
  save_user_to_yaml(user)
end

before do
  # create_dev_user # developement only

  # redirect '/signin' unless session[:username] || request.path_info == '/signin'
end

get '/' do
  verify_signed_in
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
    user = retrieve_user("#{username}.yml")
    name = user.name
    if user.username == username && user.password == params[:password]
      session[:username] = username
      session[:name] = name
      session[:msg] = "Hello #{name}!"
      redirect '/inventories'
    else
      session[:msg] = "Wrong username or password"
      erb :signin
    end
  else
    session[:msg] = "That username does not exist"
    erb :signin
  end
end

post '/signout' do
  session[:msg] = "#{session.delete(:name)} has signed out. See you soon!"
  session.delete(:username)
  redirect '/signin'
end

get '/inventories' do
  verify_signed_in
  @inventories = retrieve_user("#{session[:username]}.yml").inventories
  erb :inventory_list
end

get '/inventories/:inv_name' do
  verify_signed_in
  inventory = @user.inventories[params[:inv_name]]
  @colors = inventory.stocked_items
  erb :inventory
end

get '/register' do
  erb :register
end

post '/register' do
  if valid_password?
    session[:msg] = "Account created! You may now sign in."
    create_user
    redirect '/signin'
  else
    session[:msg] = "It looks like your passwords don't match. *cry*"
    erb :register
  end
end

class Inventory
  attr_accessor :stocked_items, :name

  def initialize(name, user)
    @name = name
    @users = user
    @stocked_items = []
  end

  def add_new_color(line, intensity, hue, count)
    stocked_items << Color.new(line, intensity, hue, count)
  end
end

class Product
end

class Color < Product
  attr_accessor :line, :intensity, :hue, :count

  def initialize(line, intensity, hue, count)
    @line = line
    @intensity = intensity
    @hue = hue
    @count = count
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