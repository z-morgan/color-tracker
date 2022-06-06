### Postgres interface library ###

require 'pg'

####### PostgresDB-specific testing setup/teardown #######

module PostgresDBSetup
  def setup
    @test_connection = PG.connect(dbname: "salon_inventory_db")
    
    sql1 = <<~SQL
      INSERT INTO users (id, username, password, first_name)
      VALUES (111111, 'admin', 'secret', 'Mr. Admin');
    SQL

    sql2 = <<~SQL
      INSERT INTO inventories (id, user_id, name)
      VALUES (222222, 111111, 'Mr. Admin''s 1st Inventory'),
      (333333, 111111, 'Mr. Admin''s 2nd Inventory');
    SQL

    sql3 = <<~SQL
      INSERT INTO lines (id, name)
      VALUES (444444, 'Wella'), (555555, 'Difiaba');
    SQL

    sql4 = <<~SQL
      INSERT INTO inventories_lines (inventory_id, line_id)
      VALUES (222222, 444444), (222222, 555555),
      (333333, 444444), (333333, 555555);
    SQL

    sql5 = <<~SQL
      INSERT INTO colors
      (id, inventory_id, line_id, depth, tone, count)
      VALUES (888880, 222222, 444444, '10', '2', 1),
      (888881, 222222, 555555, '8', '3', 4),
      (888882, 333333, 444444, '10', '2', 1),
      (888883, 333333, 555555, '8', '3', 4);
    SQL

    [sql1, sql2, sql3, sql4, sql5].each do |sql|
      @test_connection.exec(sql)
    end
  end

  def teardown
    @test_connection.exec("DELETE FROM users;")
    @test_connection.exec("DELETE FROM lines;")
    @test_connection.close
  end

  def session
    last_request.env["rack.session"]
  end

  def signed_in
    { "rack.session" => { username: "admin", name: "Mr. Admin" } }
  end

  def setup_for_test_add_item_no_lines
    sql1 = <<~SQL
      INSERT INTO users (id, username, password, first_name)
      VALUES (999999, 'admin2', 'secret2', 'admin2');
    SQL
      
    sql2 = <<~SQL
      INSERT INTO inventories (id, user_id, name)
      VALUES (999999, 999999, 'Test Inventory');
    SQL

    @test_connection.exec(sql1)
    @test_connection.exec(sql2)
  end
end

####### Application Class Definitions #######

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

class PostgresDB
  def initialize(connection)
    @connection = connection
  end

  def user_password(username)
    sql = "SELECT password FROM users WHERE username = $1;"
    @connection.exec_params(sql, [username]).values[0][0]
  end

  def user_exists?(username)
    sql = "SELECT 1 FROM users WHERE username = $1;"
    !(@connection.exec_params(sql, [username]).values.empty?)
  end

  def user_first_name(username)
    sql = "SELECT first_name FROM users WHERE username = $1;"
    @connection.exec_params(sql, [username]).values[0][0]
  end

  def user_inventories(username)
    sql = <<~SQL
      SELECT i.name FROM inventories AS i
      INNER JOIN users AS u ON u.id = i.user_id
      WHERE u.username = $1;
    SQL

    @connection.exec_params(sql, [username]).column_values(0)
  end

  def create_new_inventory(inv_name, username)
    sql = <<~SQL
      INSERT INTO inventories (user_id, name)
      VALUES ((SELECT id FROM users WHERE username = $1), $2);
    SQL

    @connection.exec_params(sql, [username, inv_name])
  end

  def line_exists_in_inventory?(line_name, inv_name, username)
    sql = <<~SQL
      SELECT 1 FROM lines AS l
      INNER JOIN inventories_lines AS il ON l.id = il.line_id
      INNER JOIN inventories AS i ON i.id = il.inventory_id
      INNER JOIN users AS u ON u.id = i.user_id
      WHERE u.username = $1 AND i.name = $2 AND l.name = $3;
    SQL

    !(@connection.exec_params(sql, [username, inv_name, line_name]).values.empty?)
  end

  # Before establishing the relationship between the line and inventory, checks
  # to see if the line exists anywhere in the database, and if not, creates it. 
  def add_new_color_line(line_name, inv_name, username)
    unless line_exists?(line_name)
      sql = "INSERT INTO lines (name) VALUES ($1);"
      @connection.exec_params(sql, [line_name])
    end

    sql = <<~SQL
      INSERT INTO inventories_lines (inventory_id, line_id)
      VALUES (
        (SELECT id FROM inventories WHERE user_id = (
         SELECT id FROM users WHERE username = $1) 
         AND name = $2),
        (SELECT id FROM lines WHERE name = $3)
      );
    SQL

    @connection.exec_params(sql, [username, inv_name, line_name])
  end

  # If the color is in stock already, adds N more. If not, creates it with 
  # a count of N.
  def add_color(line_name, depth, tone, count, inv_name, username)
    if color_in_stock?(line_name, depth, tone, inv_name, username)
      sql = <<~SQL
        UPDATE colors SET count = count + $6 WHERE id = (
          SELECT c.id FROM colors AS c
          INNER JOIN inventories AS i ON i.id = c.inventory_id
          INNER JOIN lines AS l ON l.id = c.line_id
          INNER JOIN users AS u ON u.id = i.user_id
          WHERE u.username = $1 AND i.name = $2 AND l.name = $3
          AND c.depth = $4 AND c.tone = $5
        );
      SQL
    else
      sql = <<~SQL
        INSERT INTO colors (inventory_id, line_id, depth, tone, count)
        VALUES (
          (SELECT id FROM inventories WHERE name = $2
          AND user_id = (SELECT id FROM users WHERE username = $1)),
          (SELECT id FROM lines WHERE name = $3),
          $4, $5, $6
        )
      SQL
    end
    @connection.exec_params(sql, [username, inv_name, line_name, depth, tone, count])
  end

  # Subtracts 1 from the count. If count is 1, deletes the color instead.
  def use_color(username, inv_name, line, depth, tone)
    if count_colors_in_stock(username, inv_name, line, depth, tone) > 1
      sql = <<~SQL
        UPDATE colors SET count = count - 1 WHERE id = (
          SELECT c.id FROM colors AS c
          INNER JOIN inventories AS i ON i.id = c.inventory_id
          INNER JOIN lines AS l ON l.id = c.line_id
          INNER JOIN users AS u ON u.id = i.user_id
          WHERE u.username = $1 AND i.name = $2 AND l.name = $3
          AND c.depth = $4 AND c.tone = $5
        );
      SQL
    else
      sql = <<~SQL
        DELETE FROM colors WHERE id = (
          SELECT c.id FROM colors AS c
          INNER JOIN inventories AS i ON i.id = c.inventory_id
          INNER JOIN lines AS l ON l.id = c.line_id
          INNER JOIN users AS u ON u.id = i.user_id
          WHERE u.username = $1 AND i.name = $2 AND l.name = $3
          AND c.depth = $4 AND c.tone = $5
        );
      SQL
    end

    @connection.exec_params(sql, [username, inv_name, line, depth, tone])
  end

  # Determines if there are any lines associated with the inventory yet.
  def no_lines?(inv_name, username)
    sql = <<~SQL
      SELECT 1 FROM inventories_lines WHERE inventory_id = (
        SELECT id FROM inventories WHERE name = $2 AND user_id = (
          SELECT id FROM users WHERE username = $1
        )
      );
    SQL

    @connection.exec_params(sql, [username, inv_name]).values.empty?
  end

  # Returns an array of strings which are line names in the inv
  def retrieve_lines(inv_name, username)
    sql = <<~SQL
      SELECT l.name FROM lines AS l
      INNER JOIN inventories_lines AS il ON l.id = il.line_id
      INNER JOIN inventories AS i ON i.id = il.inventory_id
      INNER JOIN users AS u ON u.id = i.user_id
      WHERE u.username = $1 AND i.name = $2;
    SQL

    @connection.exec_params(sql, [username, inv_name]).column_values(0)
  end

  # Returns an array of Color objects
  def retrieve_colors(inv_name, username)
    sql = <<~SQL
      SELECT l.name, c.depth, c.tone, c.count FROM colors AS c
      INNER JOIN inventories AS i ON i.id = c.inventory_id
      INNER JOIN users AS u ON u.id = i.user_id
      INNER JOIN lines AS l ON l.id = c.line_id
      WHERE u.username = $1 AND i.name = $2;
    SQL

    result = @connection.exec_params(sql, [username, inv_name])
    result.each_row.with_object([]) do |row, colors_arr|
      colors_arr << Color.new(*row)
    end
  end

  def create_user(username, password, name)
    unless ENV["RACK_ENV"] == "test"
      password = BCrypt::Password.create(password)
    end

    sql = <<~SQL
      INSERT INTO users (username, password, first_name)
      VALUES ($1, $2, $3);
    SQL

    @connection.exec_params(sql, [username, password, name])
  end

  def disconnect
    @connection.close
  end

  private

  def line_exists?(line_name)
    sql = "SELECT 1 FROM lines WHERE name = $1"
    !(@connection.exec_params(sql, [line_name]).values.empty?)
  end

  def color_in_stock?(line_name, depth, tone, inv_name, username)
    sql = <<~SQL
      SELECT 1 FROM colors AS c
      INNER JOIN inventories AS i ON i.id = c.inventory_id
      INNER JOIN lines AS l ON l.id = c.line_id
      INNER JOIN users AS u ON u.id = i.user_id
      WHERE u.username = $1 AND i.name = $2 AND l.name = $3
      AND c.depth = $4 AND c.tone = $5 
    SQL

    !(@connection.exec_params(sql, [username, inv_name, line_name, depth, tone]).values.empty?)
  end

  def count_colors_in_stock(username, inv_name, line, depth, tone)
    sql = <<~SQL
        SELECT count FROM colors AS c
        INNER JOIN inventories AS i ON i.id = c.inventory_id
        INNER JOIN lines AS l ON l.id = c.line_id
        INNER JOIN users AS u ON u.id = i.user_id
        WHERE u.username = $1 AND i.name = $2 AND l.name = $3
        AND c.depth = $4 AND c.tone = $5 
    SQL

    @connection.exec_params(sql, [username, inv_name, line, depth, tone]).values[0][0].to_i
  end
end

####### Database Startup method #######

def init_db
  connection = if Sinatra::Base.production?
                 PG.connect(ENV['DATABASE_URL'])
               else
                 PG.connect(dbname: "salon_inventory_db")
               end
               
  PostgresDB.new(connection)
end