require 'pg'

### Database Startup method ###

def init_db
  connection = if Sinatra::Base.production?
                 PG.connect(ENV['DATABASE_URL'])
               elsif Sinatra::Base.test?
                 PG.connect(dbname: "salon_inventory_db_test")
               else
                 PG.connect(dbname: "salon_inventory_db")
               end
               
  PostgresDB.new(connection)
end

### Postgres interface ###

class PostgresDB
  def initialize(connection)
    @connection = connection
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

  def retrieve_inventory(username, inv_name)
    lines = {}

    line_names(inv_name, username).each do |line_name|
      lines[line_name] = []
    end

    colors_in_inventory(username, inv_name).each do |color|
      lines[color.line] << color
    end

    Inventory.new(lines)
  end

  def reset_demo_account
    setup_file_name = File.expand_path("../../data/stylishowl.sql", __FILE__)
    statements_arr = File.open(setup_file_name, "r").read.split("\n\n")
    
    statements_arr.each do |sql|
      @connection.exec_params(sql)
    end
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

  def add_new_color_line(line_name, inv_name, username)
    unless line_exists?(line_name)
      sql = "INSERT INTO lines (name) VALUES ($1);"
      @connection.exec_params(sql, [line_name])
    end

    sql = <<~SQL
      INSERT INTO inventories_lines (inventory_id, line_id)
      VALUES ((SELECT id FROM inventories WHERE user_id = (
         SELECT id FROM users WHERE username = $1) AND name = $2),
        (SELECT id FROM lines WHERE name = $3));
    SQL

    @connection.exec_params(sql, [username, inv_name, line_name])
  end

  def add_color(line_name, depth, tone, count, inv_name, username)
    sql = if color_in_stock?(line_name, depth, tone, inv_name, username)
            <<~SQL
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
            <<~SQL
              INSERT INTO colors (inventory_id, line_id, depth, tone, count)
              VALUES (
                (SELECT id FROM inventories WHERE name = $2
                AND user_id = (SELECT id FROM users WHERE username = $1)),
                (SELECT id FROM lines WHERE name = $3),
                $4, $5, $6
              )
            SQL
          end

    @connection.exec_params(sql, 
                          [username, inv_name, line_name, depth, tone, count])
  end

  def use_color(username, inv_name, line, depth, tone)
    sql = if count_colors_in_stock(username, inv_name, line, depth, tone) > 1
            <<~SQL
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
            <<~SQL
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

  def disconnect
    @connection.close
  end

  private

  def line_names(inv_name, username)
    sql = <<~SQL
      SELECT l.name FROM lines AS l
      INNER JOIN inventories_lines AS il ON l.id = il.line_id
      INNER JOIN inventories AS i ON i.id = il.inventory_id
      INNER JOIN users AS u ON u.id = i.user_id
      WHERE u.username = $1 AND i.name = $2
    SQL

    @connection.exec_params(sql, [username, inv_name]).column_values(0)
  end

  def colors_in_inventory(username, inv_name)
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

    !(@connection.exec_params(sql, 
                        [username, inv_name, line_name, depth, tone]).values.empty?)
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

    @connection.exec_params(sql, 
                        [username, inv_name, line, depth, tone]).values[0][0].to_i
  end
end
