system "createdb salon_inventory_db"
system "createdb salon_inventory_db_test"

system "psql salon_inventory_db < schema.sql"
system "psql salon_inventory_db_test < schema.sql"

