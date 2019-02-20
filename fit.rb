require 'sinatra'
require 'sinatra/content_for'
require 'tilt/erubis'
require_relative "database.rb"

configure do
  enable :sessions
  set :session_secret, 'secret' # this will need to be something in a hidden file
  set :erb, :escape_html => true
end

configure(:development) do
  require 'sinatra/reloader'
  also_reload 'database.rb'
end

helpers do
end

before do
  @storage = Database.new(logger)
end

after do
  @storage.disconnect
end

def clean_name(user_name)
  user_name.gsub(/[^a-z]/i, '')
end

# show all users
get '/' do
  @users = @storage.all_users
  erb :home
end

# show new user creation page
get '/user/new' do
  erb :new_user
end

# create new user
post '/user/new' do
  user_name = clean_name(params[:user_name])

  if user_name.empty?
    session[:alert] = 'Usernames can only contain letters (a-z)'
    redirect '/user/new'
  end

  if @storage.all_users.map { |user| user[:name].downcase }.include? user_name.downcase
    session[:alert] = 'Sorry, that username already exists'
    redirect '/user/new'
  end

  @storage.create_user(user_name)
  session[:alert] = "Username \"#{user_name}\" was created"

  redirect '/'
end

# show user profile
get '/user/:user_id' do
  user_id = params[:user_id]
  @user = @storage.find_user(user_id)
  @health_stats = @storage.health_stats_for(user_id)
  @workouts = @storage.workouts_for(user_id)
  erb :user
end

# create new health stat
post '/user/:user_id/health_stat/new' do
  @storage.create_health_stat(params)
  redirect "/user/#{params[:user_id]}"
end

# delete health stat
post '/user/:user_id/health_stat/delete/:health_stat_id' do
  @storage.delete_health_stat(params[:health_stat_id])
  redirect "/user/#{params[:user_id]}"  
end

# delete user
post '/user/:user_id/delete' do
  @storage.delete_user(params[:user_id])
  redirect '/'
end