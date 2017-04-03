# Example program to insert data into details and quotes tables

require 'pg'
load "./local_env.rb" if File.exists?("./local_env.rb")

begin

  # user data sets
  user_1 = ["John", 41, 7, 11, 3, "Research is what I'm doing when I don't know what I'm doing."]
  user_2 = ["Jane", 51, 1, 2, 3, "Life is 10% what happens to you and 90% how you react to it."]
  user_3 = ["Jim", 61, 10, 20, 30, "In order to succeed, we must first believe that we can."]
  user_4 = ["Jill", 71, 11, 22, 33, "It does not matter how slowly you go as long as you do not stop."]
  user_5 = ["June", 81, 20, 40, 60, "Problems are not stop signs, they are guidelines."]
  user_6 = ["Jen", 91, 2, 4, 6, "If you fell down yesterday, stand up today."]
  user_7 = ["Jeff", 101, 37, 47, 87, "The way to get started is to quit talking and begin doing."]

  # aggregate user data into multi-dimensional array for iteration
  users = []
  users.push(user_1, user_2, user_3, user_4, user_5, user_6, user_7)

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

  # determine current max index (id) in details table
  max_id = conn.exec("select max(id) from details")[0]

  # set index variable based on current max index value
  max_id["max"] == nil ? v_id = 1 : v_id = max_id["max"].to_i + 1

  # iterate through multi-dimensional users array for data
  users.each do |user|

    # initialize variables for SQL insert statements
    v_name = user[0]
    v_age = user[1]
    v_num_1 = user[2]
    v_num_2 = user[3]
    v_num_3 = user[4]
    v_quote = user[5]

=begin
    # Keep for future reference, but don't use db for images
    # prepare image for database insertion (use strict base64 encoding)
    file_open = File.binread("./public/images/user_#{v_id}.png")
    blob = Base64.strict_encode64(file_open)
=end

    # prepare SQL statement to insert user data into details table
    conn.prepare('q_statement',
                 "insert into details (id, name, age)
                  values($1, $2, $3)")  # bind parameters

    # execute prepared SQL statement
    conn.exec_prepared('q_statement', [v_id, v_name, v_age])

    # deallocate prepared statement variable (avoid error "prepared statement already exists")
    conn.exec("deallocate q_statement")

    # prepare SQL statement to insert favorite numbers into numbers table
    conn.prepare('q_statement',
                 "insert into numbers (id, details_id, num_1, num_2, num_3)
                  values($1, $2, $3, $4, $5)")  # bind parameters

    # execute prepared SQL statement
    conn.exec_prepared('q_statement', [v_id, v_id, v_num_1, v_num_2, v_num_3])

    # deallocate prepared statement variable (avoid error "prepared statement already exists")
    conn.exec("deallocate q_statement")

    # prepare SQL statement to insert user quote into quotes table
    conn.prepare('q_statement',
                 "insert into quotes (id, details_id, quote)
                  values($1, $2, $3)")  # bind parameters

    # execute prepared SQL statement
    conn.exec_prepared('q_statement', [v_id, v_id, v_quote])

    # deallocate prepared statement variable (avoid error "prepared statement already exists")
    conn.exec("deallocate q_statement")

    # increment index value for next iteration
    v_id += 1

  end

rescue PG::Error => e

  puts 'Exception occurred'
  puts e.message

ensure

  conn.close if conn

end