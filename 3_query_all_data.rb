# Example program to return all data from details and quotes tables

require 'pg'
load "./local_env.rb" if File.exists?("./local_env.rb")

def get_data(user_name)

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

    # reference - example query to return all column names from details table
    # select column_name from information_schema.columns where table_name='details'

    # prepare SQL statement
    conn.prepare('q_statement',
                 "select *
                  from details
                  join numbers on details.id = numbers.details_id
                  join quotes on details.id = quotes.details_id
                  where details.name = '#{user_name}'")

=begin
  # reference - example query to skip additional id columns in numbers and quotes
  # prepare data for iteration
  conn.prepare('q_statement',
               "select details.id, name, age, n1, n2, n3, quote
               from details
               join numbers on details.id = numbers.details_id
               join quotes on details.id = quotes.details_id")
=end

    # execute prepared SQL statement
    rs = conn.exec_prepared('q_statement')

    # deallocate prepared statement variable (avoid error "prepared statement already exists")
    conn.exec("deallocate q_statement")

    return rs[0]

=begin
  # Keep for future reference, but don't use db for images
  # Working on reading base64 back out of bytea field - currently getting mangled
  # conn.prepare('q_statement', "select encode(image::bytea, 'UTF8') as image from images")
  # rs = conn.exec_prepared('q_statement')
=end

  #   # iterate through each row for user data and image
  #   rs.each do |row|

  #     # output user data to console
  #     puts "Details ID: #{row['id']}"
  #     puts "Images ID: #{row['details_id']}"
  #     puts "Name: #{row['name']}"
  #     puts "Age: #{row['age']}"
  #     puts "Favorite number 1: #{row['n1']}"
  #     puts "Favorite number 2: #{row['n2']}"
  #     puts "Favorite number 3: #{row['n3']}"
  #     puts "Quote: #{row['quote']}"

  # =begin
  #     # Keep for future reference, but don't use db for images
  #     # output user image to current directory, use strict base64 decoding
  #     # image = row['image']
  #     # f = File.new "#{row['name']}_#{row['id']}_output.png", "wb"
  #     # f.write(Base64.decode64(image))
  #     # f.close if f
  # =end

  #   end

    # --- Example output ---
    # Details ID: 1
    # Images ID: 1
    # Name: John
    # Age: 41
    # Favorite number 1: 7
    # Favorite number 2: 11
    # Favorite number 3: 3
    # Quote: Research is what I'm doing when I don't know what I'm doing.
    # --------------------

  rescue PG::Error => e

    puts 'Exception occurred'
    puts e.message

  ensure

    conn.close if conn

  end

end

p get_data("John")