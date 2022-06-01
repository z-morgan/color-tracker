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
    @user.inventories["Mr. Admin's 1st Inventory"] = Inventory.new("Mr. Admin's 1st Inventory")
    @user.inventories["Mr. Admin's 2nd inventory"] = Inventory.new("Mr. Admin's 2nd inventory")
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

  ########### tests #############

  def test_homepage_not_signed_in
    get '/'
    assert_equal 302, last_response.status
    assert_equal "Please sign in first.", session[:msg]
    
    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, %q(<form action="/signin" method="post")
  end

  def test_homepage_signed_in
    get '/', {}, signed_in
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Mr. Admin's Inventories"
  end

  def test_register_page
    get '/register'
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, %q(<form action="/register" method="post")
  end

  def test_register_new_user
    post '/register', { username: "admin2", password: "secret2", password2: "secret2", name: "Mrs. Admin" }
    assert_equal 302, last_response.status
    assert_equal "Account created! You may now sign in.", session[:msg]

    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, %q(<form action="/signin" method="post")

    post '/signin', {username: "admin2", password: "secret2"}
    assert_equal 302, last_response.status
    assert_equal "Hello Mrs. Admin!", session[:msg]
  end

  def test_register_mismatched_passwords
    post '/register', { username: "admin2", password: "secret2", password2: "secret3", name: "Mrs. Admin" }
    assert_equal 422, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "It looks like your passwords don't match. *cry*"
  end

  def test_signin_page
    get '/signin'
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, %q(<form action="/signin" method="post")
  end

  def test_signing_in_success
    post '/signin', {username: "admin", password: "secret"}
    assert_equal 302, last_response.status
    assert_equal "Hello Mr. Admin!", session[:msg]

    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Mr. Admin's Inventories"
  end

  def test_signing_in_wrong_username
    post '/signin', { username: "adminx", password: "secret" }
    assert_equal 422, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "That username does not exist"
  end

  def test_signing_in_wrong_password
    post '/signin', { username: "admin", password: "secrets" }
    assert_equal 422, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Wrong username or password"
  end

  def test_inventores_list
    get '/inventories', {}, signed_in
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Mr. Admin's Inventories"
    assert_includes last_response.body, "Mr. Admin's 1st Inventory"
  end

  def test_new_inventory_page
    get "/inventories/new", {}, signed_in
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, %q(What is the name of the new inventory?)
  end

  def test_add_new_inventory
    post "/inventories/new", { new_inventory: "My New Inventory" }, signed_in
    assert_equal 302, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_equal "Inventory Added.", session[:msg]

    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "My New Inventory"
  end

  def test_add_invalid_inventory_name
    post "/inventories/new", { new_inventory: "My_New_Inventory" }, signed_in
    assert_equal 422, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "The name can only have letters, "\
    "numbers, spaces, dashes, periods, and apostrophies."
  end

  def test_viewing_inventory
    get "/inventories/Mr.%20Admin's%201st%20Inventory", {}, signed_in
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<table>"
    assert_includes last_response.body, %q(<td>10/2</td>)
    assert_includes last_response.body, %q(<td>Wella</td>)
    assert_includes last_response.body, %q(<td>1</td>)
  end

  def test_add_item_page
    get "/inventories/Mr.%20Admin's%201st%20Inventory/add", {}, signed_in
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<table>"
    assert_includes last_response.body, %q(<td>10/2</td>)
    assert_includes last_response.body, %q(method="post")
  end

  def test_add_item_no_lines
    @user = User.new("admin2", "secret2", "admin2")
    @user.inventories["Test Inventory"] = Inventory.new("Test Inventory")
    save_user_to_yaml(@user)

    get "/inventories/Test%20Inventory/add", {}, {"rack.session" => { username: "admin2" } }
    assert_equal 302, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_equal "You need to add a color line first.", last_request.env["rack.session"][:msg]

    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "You don't have any color lines yet."
  end

  def test_add_new_color
    post "/inventories/Mr.%20Admin's%201st%20Inventory/add", \
      { line: "Wella", depth: "5", tone: "3", count: "2" }, signed_in
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, %q(<td>5/3</td>)
    assert_includes last_response.body, %q(<td>2</td>)
  end

  def test_add_stocked_color
    post "/inventories/Mr.%20Admin's%201st%20Inventory/add", \
      { line: "Wella", depth: "10", tone: "2", count: "3" }, signed_in
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, %q(<td>10/2</td>)
    assert_includes last_response.body, %q(<td>4</td>)
  end

  def test_add_empty_attribute
    post "/inventories/Mr.%20Admin's%201st%20Inventory/add", \
      { line: "Wella", depth: "1", tone: "2", count: "" }, signed_in

  end

  def test_new_line_page
    get "/inventories/Mr.%20Admin's%201st%20Inventory/new-line", {}, signed_in
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, %q(What is the name of the new line?)
  end

  def test_add_new_line
    post "/inventories/Mr.%20Admin's%201st%20Inventory/new-line", \
      { line: "Cosmoprof" }, signed_in
    assert_equal 302, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_equal "Color line added.", session[:msg]

    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Cosmoprof"
  end

  def test_add_invalid_line
    post "/inventories/Mr.%20Admin's%201st%20Inventory/new-line", \
      { line: "Cosmoprof_and_company" }, signed_in
    assert_equal 422, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "The name can only have letters, numbers,"\
    " spaces, dashes, periods, and apostrophies."
  end

  def test_add_duplicate_line
    post "/inventories/Mr.%20Admin's%201st%20Inventory/new-line", \
      { line: "Wella" }, signed_in
    assert_equal 422, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "That line already exists!"
  end

  def test_use_color_1_of_4
    post "/inventories/Mr.%20Admin's%201st%20Inventory/use", \
      { color: "Difiaba_8_3" }, signed_in
    assert_equal 302, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_equal "Color product used", session[:msg]

    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, %q(<td>8/3</td>)
    assert_includes last_response.body, %q(<td>3</td>)
  end

  def test_use_color_4_of_4
    post "/inventories/Mr.%20Admin's%201st%20Inventory/use", \
      { color: "Difiaba_8_3" }, signed_in
    post "/inventories/Mr.%20Admin's%201st%20Inventory/use", \
      { color: "Difiaba_8_3" }, signed_in
    post "/inventories/Mr.%20Admin's%201st%20Inventory/use", \
      { color: "Difiaba_8_3" }, signed_in
    post "/inventories/Mr.%20Admin's%201st%20Inventory/use", \
      { color: "Difiaba_8_3" }, signed_in

    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    refute_includes last_response.body, %q(<td>8/3</td>)
    refute_includes last_response.body, %q(<td>3</td>)
  end

  def test_sort
    post "/inventories/Mr.%20Admin's%201st%20Inventory/add", \
      { line: "Wella", depth: "9", tone: "7", count: "1" }, signed_in
    post "/inventories/Mr.%20Admin's%201st%20Inventory/add", \
      { line: "Difiaba", depth: "6", tone: "5", count: "1" }

    get "/inventories/Mr.%20Admin's%201st%20Inventory", \
      { attribute: "tone", order: "ascending" }
    assert_match /2.+7/m, last_response.body

    get "/inventories/Mr.%20Admin's%201st%20Inventory", \
      { attribute: "tone", order: "descending" }
    assert_match /7.+2/m, last_response.body

    get "/inventories/Mr.%20Admin's%201st%20Inventory", \
      { attribute: "depth", order: "ascending" }
    assert_match /6.+8/m, last_response.body

    get "/inventories/Mr.%20Admin's%201st%20Inventory", \
      { attribute: "depth", order: "descending" }
    assert_match /8.+6/m, last_response.body
  end
end