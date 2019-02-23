require 'sinatra'
require 'sinatra/content_for'
require 'tilt/erubis'
require_relative "database.rb"

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

configure(:development) do
  require 'sinatra/reloader'
  also_reload 'database.rb'
  also_reload '/stylesheets/application.css'
end

helpers do
end

before do
  @storage = Database.new(logger)
end

after do
  @storage.disconnect
end

get '/' do
  redirect '/home' if !!session[:user]
  redirect '/login'
end

# user login
get '/login' do
  # eventually needs to be a login screen
  session[:user] = @storage.get_user('Will')
  redirect '/home'
end

# logout user
get '/logout' do
  session[:user] = nil
  redirect '/'
end

# portal hub
get '/home' do
  erb :home
end

# workout portal
get '/workout' do
  erb :workout
end

# body measurement portal
get '/measure' do
  user_id = session[:user][:id]
  @measurements = @storage.get_measurements(user_id)
  @today = Time.now.to_s[0..9]
  erb :measure
end

# workout management portal
get '/manage' do
  erb :manage
end

post '/measure/add' do
  @storage.add_measurement(session[:user][:id], params)
  redirect '/measure'
end

post '/measure/:id/delete' do
  @storage.delete_measurement(params[:id])
  redirect '/measure'
end
