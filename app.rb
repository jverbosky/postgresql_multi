require 'sinatra'
require_relative 'postgresql_ops.rb'

class PersonalDetailsPostgreSQLApp < Sinatra::Base

  get "/" do
    feedback = ""  # placeholders in this route to avoid error message
    name = ""
    age = ""
    n1 = ""
    n2 = ""
    n3 = ""
    quote = ""
    # variables used in /post_info route, passing empty string to view to avoid error message
    erb :get_info, locals: {feedback: feedback, name: name, age: age, n1: n1, n2: n2, n3: n3, quote: quote}
  end

  post '/post_info' do
    user_hash = params[:user]  # assign the user hash to the user_hash variable
    feedback = check_values(user_hash)  # check to see if user is already in PostgreSQL db
    write_db(user_hash)  # if not, add user info to db
    name = user_hash["name"]  # user name from the resulting hash
    age = user_hash["age"]  # user age from the resulting hash
    n1 = user_hash["n1"]  # favorite number 1 from the resulting hash
    n2 = user_hash["n2"]  # favorite number 2 from the resulting hash
    n3 = user_hash["n3"]  # favorite number 3 from the resulting hash
    total = sum(n1, n2, n3)
    comparison = compare(total, age)
    quote = user_hash["quote"]  # quote from the resulting hash
    if feedback == ""  # if there's no feedback on user already being in db, use the get_more_info view
      erb :get_more_info, locals: {name: name, age: age, n1: n1, n2: n2, n3: n3, total: total, comparison: comparison, quote: quote}
    else
      # otherwise reload the get_info view with feedback and user-specified values so they can correct and resubmit
      erb :get_info, locals: {feedback: feedback, name: name, age: age, n1: n1, n2: n2, n3: n3, quote: quote}
    end
  end

  get '/list_users' do
    names = get_names()  # get an array of all of the user names in PostgreSQL db
    erb :list_users, locals: {names: names}
  end

  get '/user_info' do
    name = params[:name]  # get the specified name from the url in list_users.erb (url = "/user_info?name=" + name)
    user_hash = get_data(name)  # get the hash of info for the specified user
    erb :user_info, locals: {user_hash: user_hash}
  end

end