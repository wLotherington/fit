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
  def public_workout(bool)
    if bool == 't'
      'fas fa-eye' 
    else
      'fas fa-eye-slash'
    end
  end

  def active_workout(bool)
    if bool == 't'
      'fas fa-check-square' 
    else
      'far fa-square'
    end
  end
end

before do
  @storage = Database.new(logger)
end

after do
  @storage.disconnect
end

get '/' do
  erb :home
end

# MEASURE
# body measurement portal
get '/measure' do
  @measurements = @storage.get_measurements
  @today = Time.now.to_s[0..9]
  erb :measure
end

# add body measurement
post '/measure/add' do
  redirect '/measure' if params[:day].empty?
  @storage.add_measurement(params)
  redirect '/measure'
end

post '/measure/:measurement_id/delete' do
  @storage.delete_measurement(params[:measurement_id])
  redirect '/measure'
end

# MANAGE
# workout management portal
get '/manage' do
  erb :manage
end

# add workout
# post '/manage/add' do
#   @measurements = @storage.add_workout(params)
#   redirect '/manage'
# end

# edit workout
# get '/manage/:id/edit' do
#   @workouts = @storage.get_workout(params[:id])
#   @exercises = @storage.get_exercises
#   erb :edit_workout
# end

# get '/manage/create_workout' do
#   erb :create_workout
# end

# post '/manage/create_workout' do
#   @storage.create_workout(params)
#   workout_id = @storage.get_workout_id(params)
#   redirect "/manage/#{workout_id}/edit"
# end

# post '/manage/:id/delete' do
#   @storage.delete_workout(params[:id])
#   redirect '/manage'
# end

# WORKOUT
# workout portal
get '/workout' do
  @workouts = @storage.get_active_workouts
  erb :workout
end

# go so specific workout
get '/workout/:workout_id' do
  workout_id = params[:workout_id]
  @workout = @storage.get_workout(workout_id)
  @exercises = @storage.get_workout_exercises(workout_id)
  @instances = @storage.get_instances(workout_id)
  erb :do_workout
end

post '/workout/:workout_id/exercise/:exercise_id/add_set' do
  unless params[:weight].empty? || params[:reps].empty?
    @storage.add_set(params)
    @storage.update_last_completed(params[:workout_id])
  end
  redirect "/workout/#{params[:workout_id]}"
end

post '/workout/:workout_id/instances/:instance_id/delete' do
  @storage.delete_instance(params[:instance_id])
  redirect "/workout/#{params[:workout_id]}"
end

# PROGRESS
# progression portal
get '/progress' do
  erb :progress
end
