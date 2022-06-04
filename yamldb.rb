### YamlDB library ###

require 'yaml'

####### YamlDB-specific testing setup/teardown #######

module YamlDBSetup
  def create_test_user
    @user = User.new("admin", "secret", "Mr. Admin")
    @user.inventories["Mr. Admin's 1st Inventory"] = Inventory.new("Mr. Admin's 1st Inventory")
    @user.inventories["Mr. Admin's 2nd Inventory"] = Inventory.new("Mr. Admin's 2nd Inventory")
    populate_inventories(@user)
    save_user_to_yaml(@user)
  end

  def save_user_to_yaml(user)
    basename = "#{user.username}.yml"
    path = File.join(data_path, basename)
    File.open(path, "w") { |f| f.write(user.to_yaml) }
  end

  def populate_inventories(user)
    user.inventories.each do |_, inv|
      inv.add_color("Wella", '10', '2', '1')
      inv.add_color("Difiaba", '8', '3', '4')
    end

    user.inventories.each do |_, inv|
      inv.lines << "Wella"
      inv.lines << "Difiaba"
    end
  end

  def session
    last_request.env["rack.session"]
  end

  def signed_in
    { "rack.session" => { username: "admin", name: "Mr. Admin" } }
  end

  def setup
    FileUtils.mkdir_p(data_path)
    FileUtils.touch(File.join(data_path, "candidate_user.yml"))
    create_test_user
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def setup_for_test_add_item_no_lines
    @user = User.new("admin2", "secret2", "admin2")
    @user.inventories["Test Inventory"] = Inventory.new("Test Inventory")
    save_user_to_yaml(@user)
  end
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

class YamlDB
  def initialize(username)
    @user = retrieve_user("#{username}.yml")
  end

  def user_password(_)
    @user.password
  end

  def user_exists?(username)
    unless Dir.glob(File.join(data_path, username) + ".yml").empty?
      @user = retrieve_user("#{username}.yml")
    end

    @user.username == username
  end

  def user_first_name(_)
    @user.name
  end

  def user_inventories(_)
    @user.inventories.keys
  end

  def create_new_inventory(name, _)
    @user.inventories[name] = Inventory.new(name)
    save_user_to_yaml(@user)
  end

  def line_exists_in_inventory?(name, inv_name, _)
    retrieve_lines(inv_name, nil).include?(name)
  end

  def add_new_color_line(name, inv_name, _)
    retrieve_lines(inv_name, nil) << name
    save_user_to_yaml(@user)
  end

  def add_color(line, depth, tone, count, inv_name, _)
    retrieve_inventory(inv_name).add_color(line, depth, tone, count)
    save_user_to_yaml(@user)
  end

  def use_color(_, inv_name, line, depth, tone)
    inventory = retrieve_inventory(inv_name)
    inventory.use_color(line, depth, tone)
    save_user_to_yaml(@user)
  end

  def no_lines?(inv_name, _)
    retrieve_lines(inv_name, nil).empty?
  end

  def retrieve_lines(inv_name, _)
    @user.inventories[inv_name].lines
  end

  def retrieve_colors(inv_name, _)
    @user.inventories[inv_name].stocked_items
  end

  def create_user(username, password, name)
    unless ENV["RACK_ENV"] == "test"
      password = BCrypt::Password.create(password)
    end
  
    user = User.new(username, password, name)
    save_user_to_yaml(user)
  end

  def disconnect
  end

  private

  def retrieve_inventory(inv_name)
    @user.inventories[inv_name]
  end

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

### Database Startup method ###

def init_db
  username = session[:username]
  username = "candidate_user" if username.nil?
  if Dir.glob(File.join(data_path, username) + ".yml").empty?
    username = "candidate_user"
  end

  YamlDB.new(username)
end