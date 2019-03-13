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

  def active?(bool)
    if bool == 'f'
      ""
    else
      "check-"
    end
  end

  def reccommend_weight(exercise)
    total_weight = @storage.last_weight(exercise[:workout_exercise_id])
    if !!total_weight
      (total_weight.to_f / exercise[:target_reps].to_f / exercise[:target_sets].to_f).round(2)
    else
      exercise[:starting_weight]
    end
  end
end

def valid_exercise?(params)
  return false if params[:exercise_name].empty?
  return false if params[:sets].empty?
  return false if params[:reps].empty?
  return false if params[:weight].empty?
  true
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
  @workouts = @storage.get_all_workouts
  erb :manage
end

post '/manage/:workout_id/delete' do
  workout_id = params[:workout_id]
  @storage.delete_workout(workout_id)
  redirect '/manage'
end

post '/manage/add' do
  workout_name = params[:workout_name].strip
  redirect '/manage' if workout_name.empty?
  @storage.create_workout(workout_name)
  workout_id = @storage.get_largest_workout_id
  workout_id
  redirect "/manage/#{workout_id}/edit"
end

get '/manage/:workout_id/edit' do
  @workout = @storage.get_workout(params[:workout_id])
  @exercises = @storage.get_exercises
  @workout_exercises = @storage.get_manage_workout_exercises(@workout[:id])
  erb :edit_workout
end

post '/manage/:workout_id/exercise/:exercise_id/delete' do
  @storage.delete_exercise(params[:exercise_id])
  redirect "/manage/#{params[:workout_id]}/edit"
end

post '/manage/:workout_id/exercise/add' do
  redirect "/manage/#{params[:workout_id]}/edit" unless valid_exercise?(params)
  @storage.create_exercise(params)
  redirect "/manage/#{params[:workout_id]}/edit"
end

post '/manage/:workout_id/exercise/:exercise_name/add' do
  redirect "/manage/#{params[:workout_id]}/edit" unless valid_exercise?(params)
  @storage.add_exercise(params)
  redirect "/manage/#{params[:workout_id]}/edit"
end

post '/manage/:workout_id/workout_exercise/:workout_exercise_id/delete' do
  @storage.delete_workout_exercise(params[:workout_exercise_id])
  redirect "/manage/#{params[:workout_id]}/edit"
end

post '/manage/:workout_id/:toggle' do
  state = params[:toggle] == 't' ? 'FALSE' : 'TRUE'
  @storage.toggle_workout(params[:workout_id], state)
  redirect "/manage/#{params[:workout_id]}/edit"
end

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
  puts "============================"
  puts "============================"
  puts @instances
  puts
  puts "============================"
  puts
  puts @exercises
  puts "============================"
  puts "============================"
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
