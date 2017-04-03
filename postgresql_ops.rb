require 'pg'
load "./local_env.rb" if File.exists?("./local_env.rb")

# Method to open a connection to the PostgreSQL database
def open_db()
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
  rescue PG::Error => e
    puts 'Exception occurred'
    puts e.message
  end
end

# Method to return user hash from SQLite db for specified user
def get_data(user_name)
  begin
    conn = open_db()
    conn.prepare('q_statement',
                 "select *
                  from details
                  join numbers on details.id = numbers.details_id
                  join quotes on details.id = quotes.details_id
                  where details.name = '#{user_name}'")
    user_hash = conn.exec_prepared('q_statement')
    conn.exec("deallocate q_statement")
    return user_hash[0]
  rescue PG::Error => e
    puts 'Exception occurred'
    puts e.message
  ensure
    conn.close if conn
  end
end

# Method to rearrange names for (top > down) then (left > right) column population
def rotate_names(names)
  quotient = names.count/3  # baseline for number of names per column
  names.count % 3 > 0 ? remainder = 1 : remainder = 0  # remainder to ensure no names dropped
  max_column_count = quotient + remainder  # add quotient & remainder to get max number of names per column
  matrix = names.each_slice(max_column_count).to_a    # names divided into three (inner) arrays
  results = matrix[0].zip(matrix[1], matrix[2]).flatten   # names rearranged (top > bottom) then (left > right) in table
  results.each_index { |name| results[name] ||= "" }  # replace any nils (due to uneven .zip) with ""
end

# Method to return array of sorted/transposed names from db for populating /list_users table
def get_names()
  begin
    names = []
    conn = open_db()
    conn.prepare('q_statement',
                 "select name from details order by name")
    query = conn.exec_prepared('q_statement')
    conn.exec("deallocate q_statement")
    query.each { |pair| names.push(pair["name"]) }
    names
    sorted = names.count > 3 ? rotate_names(names) : names  # rerrange names if more than 3 names
  rescue PG::Error => e
    puts 'Exception occurred'
    puts e.message
  ensure
    conn.close if conn
  end
end

# Method to determine if value is too long or if user in current user hash is already in JSON file
def check_values(user_hash)
  flag = 0
  feedback = ""
  detail = ""
  user_hash.each do |key, value|
    flag = 2 if key == "age" && value.to_i > 120
    (flag = 3; detail = key) if key !~ /quote/ && value.length > 20
    flag = 4 if key == "quote" && value.length > 80
    flag = 5 if key == "name" && value =~ /[^a-zA-Z ]/
    (flag = 6; detail = key) if key =~ /age|n1|n2|n3/ && value =~ /[^0-9.,]/
  end
  users = get_names()
  users.each { |user| flag = 1 if user == user_hash["name"]}
  case flag
    when 1 then feedback = "We already have details for that person - please enter a different person."
    when 2 then feedback = "I don't think you're really that old - please try again."
    when 3 then feedback = "The value for '#{detail}' is too long - please try again with a shorter value."
    when 4 then feedback = "Your quote is too long - please try again with a shorter value."
    when 5 then feedback = "Your name should only contain letters - please try again."
    when 6 then feedback = "The value for '#{detail}' should only have numbers - please try again."
  end
  return feedback
end

# Method to add current user hash to db
def write_db(user_hash)
  feedback = check_values(user_hash)
  if feedback == ""
    begin
      conn = open_db() # open database for updating
      max_id = conn.exec("select max(id) from details")[0]  # determine current max index (id) in details table
      max_id["max"] == nil ? v_id = 1 : v_id = max_id["max"].to_i + 1  # set index variable based on current max index value
      v_name = user_hash["name"]  # prepare data from user_hash for database insert
      v_age = user_hash["age"]
      v_num_1 = user_hash["n1"]
      v_num_2 = user_hash["n2"]
      v_num_3 = user_hash["n3"]
      v_quote = user_hash["quote"]
      conn.prepare('q_statement',
                   "insert into details (id, name, age)
                    values($1, $2, $3)")  # bind parameters
      conn.exec_prepared('q_statement', [v_id, v_name, v_age])
      conn.exec("deallocate q_statement")
      conn.prepare('q_statement',
                   "insert into numbers (id, details_id, num_1, num_2, num_3)
                    values($1, $2, $3, $4, $5)")  # bind parameters
      conn.exec_prepared('q_statement', [v_id, v_id, v_num_1, v_num_2, v_num_3])
      conn.exec("deallocate q_statement")
      conn.prepare('q_statement',
                   "insert into quotes (id, details_id, quote)
                    values($1, $2, $3)")  # bind parameters
      conn.exec_prepared('q_statement', [v_id, v_id, v_quote])
      conn.exec("deallocate q_statement")
    rescue PG::Error => e
      puts 'Exception occurred'
      puts e.message
    ensure
      conn.close if conn
    end
  end
end

# Method to identify which column contains the specified value
def match_column(value)
  begin
    columns = ["name", "num_1", "quote"]
    target = ""
    conn = open_db() # open database for updating
    columns.each do |column|  # determine which column contains the specified value
      query = "select " + column +
              " from details
               join numbers on details.id = numbers.details_id
               join quotes on details.id = quotes.details_id"
      conn.prepare('q_statement', query)
      rs = conn.exec_prepared('q_statement')
      conn.exec("deallocate q_statement")
      results = rs.values.flatten
      target = column if results.include? value
    end
    return target
  rescue PG::Error => e
    puts 'Exception occurred'
    puts e.message
  ensure
    conn.close if conn
  end
end


=begin

# Method to return hash of all values for record associated with specified value
def pull_record(value)
  begin

    conn = open_db()
    table = match_table(column)  # determine which table contains the specified column
    conn.prepare('q_statement',
                 "select *
                  from details
                  join numbers on details.id = numbers.details_id
                  join quotes on details.id = quotes.details_id
                  where details.name = '#{user_name}'")
    user_hash = conn.exec_prepared('q_statement')
    conn.exec("deallocate q_statement")
    return user_hash[0]


      v_quote = user_hash["quote"]
      conn.prepare('q_statement',
                   "insert into details (id, name, age)
                    values($1, $2, $3)")  # bind parameters
      conn.exec_prepared('q_statement', [v_id, v_name, v_age])
      conn.exec("deallocate q_statement")


      query = "update " + table + " set " + column + " = $2 where id = $1"
      conn.prepare('q_statement', query)
      rs = conn.exec_prepared('q_statement', [id, value])


    query = 

    # id = columns["id"]  # determine the id for the current record
    # conn = PG.connect(dbname: 'test', user: 'something', password: '4321')
    # columns.each do |column, value|  # iterate through columns hash for each column/value pair
    #   unless column == "id"  # we do NOT want to update the id
    #     table = match_table(column)  # determine which table contains the specified column
    #     # workaround for table name being quoted and column name used as bind parameter
    #     query = "update " + table + " set " + column + " = $2 where id = $1"
    #     conn.prepare('q_statement', query)
    #     rs = conn.exec_prepared('q_statement', [id, value])
    #     conn.exec("deallocate q_statement")
    #   end
    # end

  rescue PG::Error => e
    puts 'Exception occurred'
    puts e.message
  ensure
    conn.close if conn
  end
end

=end



# Method to identify which table contains the specified column
def match_table(column)
  begin
    tables = ["details", "numbers", "quotes"]
    target = ""
    conn = open_db() # open database for updating
    tables.each do |table|  # determine which table contains the specified column
      conn.prepare('q_statement',
                   "select column_name
                    from information_schema.columns
                    where table_name = $1")
      rs = conn.exec_prepared('q_statement', [table])
      conn.exec("deallocate q_statement")
      columns = rs.values.flatten
      target = table if columns.include? column
    end
    return target
  rescue PG::Error => e
    puts 'Exception occurred'
    puts e.message
  ensure
    conn.close if conn
  end
end

# Method to update any number of values in any number of tables
# - columns hash needs to contain id of current record that needs to be updated
# - order is not important (the id can be anywhere in the hash)
def update_values(columns)
  begin
    id = columns["id"]  # determine the id for the current record
    conn = open_db() # open database for updating
    columns.each do |column, value|  # iterate through columns hash for each column/value pair
      unless column == "id"  # we do NOT want to update the id
        table = match_table(column)  # determine which table contains the specified column
        # workaround for table name being quoted and column name used as bind parameter
        query = "update " + table + " set " + column + " = $2 where id = $1"
        conn.prepare('q_statement', query)
        rs = conn.exec_prepared('q_statement', [id, value])
        conn.exec("deallocate q_statement")
      end
    end
  rescue PG::Error => e
    puts 'Exception occurred'
    puts e.message
  ensure
    conn.close if conn
  end
end

# Method to return the sum of favorite numbers
def sum(n1, n2, n3)
  sum = n1.to_i + n2.to_i + n3.to_i
end

# Method to compare the sum of favorite numbers against the person's age
def compare(sum, age)
  comparison = (sum < age.to_i) ? "less" : "greater"
end

#-----------------
# Sandbox testing
#-----------------

# p get_data("John")

# user_hash = {"name" => "Jack", "age" => "37", "n1" => "8", "n2" => "16", "n3" => "24", "quote" => "You don't know... Jack."}
# write_db(user_hash)

# p get_names()

# p match_table("age")
# p match_table("quote")
# p match_table("num_3")

# hash_1 = {"id" => "3", "age" => "74", "num_1" => "100", "quote" => "Set your goals high, and don't stop till you get there."}
# hash_2 = {"age" => "93", "num_3" => "77", "id" => "6", "quote" => "The harder the conflict, the more glorious the triumph."}

# update_values(hash_1)
# update_values(hash_2)

p match_column("John")
p match_column("If you fell down yesterday, stand up today.")
p match_column("11")