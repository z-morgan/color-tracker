ENV["RACK_ENV"] = "test"

require 'minitest/autorun'
require 'rack/test'
require 'fileutils'
require_relative '../app'

class AppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def create_test_user
    @user = User.new("admin", "secret", "Mr. Admin")
    @user.inventories["Mr. Admin's 1st Inventory"] = Inventory.new("Mr. Admin's 1st Inventory", "admin")
    @user.inventories["Mr. Admin's 2nd inventory"] = Inventory.new("Mr. Admin's 2nd inventory", "admin")
    populate_inventories(@user)
    save_user_to_yaml(@user)
  end

  def populate_inventories(user)
    user.inventories.each do |_, inv|
      inv.add_new_color("wella", 10, 2, 5)
      inv.add_new_color("cosmoprof", 8, 3, 4)
    end
  end

  def setup
    FileUtils.mkdir_p(data_path)

    create_test_user
  end

  def test_connection
    get '/'
    assert_equal 302, last_response.status
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end
end