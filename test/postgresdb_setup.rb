####### PostgresDB-specific testing setup/teardown #######

module PostgresDBSetup
  def setup
    @test_connection = PG.connect(dbname: "salon_inventory_db_test")
    
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