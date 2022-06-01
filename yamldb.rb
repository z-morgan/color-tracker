### YamlDB library ###

require 'yaml'

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