# Example program to drop (delete) and create details and quotes tables

require 'pg'
load "./local_env.rb" if File.exists?("./local_env.rb")

begin

  # connect to the database
  db_params = {
        host: ENV['host'],  # AWS link
        port:ENV['port'],  # AWS port, always 5432
        dbname:ENV['dbname'],
        user:ENV['dbuser'],
        password:ENV['dbpassword']
      }
  conn = PG::Connection.new(db_params)

  # local database connection
  # db_params = {
  #   dbname:ENV['dbname'],
  #   user:ENV['dbuser'],
  #   password:ENV['dbpassword']
  # }
  # conn = PG.connect(dbname: ENV['dbname'], user: ENV['dbuser'], password: ENV['dbpassword'])

  # drop details table if it exists
  conn.exec "drop table if exists details"

  # create the details table
  conn.exec "create table details (
             id int primary key,
             name varchar(50),
             age int,
             image varchar(50))"

  # drop numbers table if it exists
  conn.exec "drop table if exists numbers"

  # create the numbers table with an implied foreign key (details_id)
  conn.exec "create table numbers (
             id int primary key,
             details_id int,
             n1 int,
             n2 int,
             n3 int)"

  # drop quotes table if it exists
  conn.exec "drop table if exists quotes"

  # create the quotes table with an implied foreign key (details_id)
  conn.exec "create table quotes (
             id int primary key,
             details_id int,
             quote varchar(255))"

=begin

  # Keep for future reference, but don't use db for images
  # - severely inflates database size
  # - doesn't scale well for serving up images
  # - impacts backup/recovery times

  # drop images table if it exists
  conn.exec "drop table if exists images"

  # create an image table with implied foreign key (details_id)
  conn.exec "create table images (
      id int primary key,
      details_id int,
      image bytea
    )"

=end

rescue PG::Error => e

  puts 'Exception occurred'
  puts e.message

ensure

  conn.close if conn

end