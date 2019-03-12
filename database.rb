require 'pg'

class Database
  def initialize(logger)
    @db = if Sinatra::Base.production?
            PG.connect(ENV['DATABASE_URL'])
          else
            PG.connect(dbname: 'fit')
          end
    @logger = logger
  end

  def disconnect
    @db.close
  end

  def get_measurements
    sql = 'SELECT * FROM measurements ORDER BY day DESC'
    results = query(sql)

    results.map do |tuple|
      {
        id: tuple['id'],
        day: tuple['day'],
        weight: tuple['weight'],
        body_fat: tuple['body_fat'],
      }
    end
  end

  # MEASURE
  def add_measurement(params)
    sql = 'INSERT INTO measurements (day, weight, body_fat) VALUES ($1, $2, $3)'
    query(sql, params[:day], params[:weight].to_f, params[:body_fat].to_f)
  end

  def delete_measurement(measurement_id)
    sql = 'DELETE FROM measurements WHERE id=$1'
    query(sql, measurement_id)
  end

  # WORKOUT
  def get_active_workouts
    sql = 'SELECT * FROM workouts WHERE active = true ORDER BY last_completed DESC'
    results = query(sql)

    results.map do |tuple|
      {
        id: tuple['id'],
        name: tuple['name'],
        time_created: tuple['time_created'],
        last_completed: tuple['last_completed'],
        active: tuple['active'],
      }
    end
  end

  def get_workout(workout_id)
    sql = 'SELECT * FROM workouts WHERE id = $1'
    result = query(sql, workout_id)
    tuple = result.first
    
    {
      id: tuple['id'],
      name: tuple['name'],
      time_created: tuple['time_created'],
      last_completed: tuple['last_completed'],
      active: tuple['active'],
    }
  end

  def get_workout_exercises(workout_id)
    sql = <<~SQL
      SELECT e.*, we.*
      FROM exercises AS e
      INNER JOIN workouts_exercises AS we ON e.id = we.exercise_id
      WHERE we.workout_id = $1
    SQL
    results = query(sql, workout_id)
    
    results.map do |tuple|
      {
        id: tuple['id'],
        name: tuple['name'],
        time_created: tuple['time_created'],
        last_completed: tuple['last_completed'],
        active: tuple['active'],
        target_sets: tuple['target_sets'],
        target_reps: tuple['target_reps'],
        starting_weight: tuple['starting_weight']
      }
    end
  end

  def get_instances(workout_id)
    sql = <<~SQL
      SELECT i.*, e.name
      FROM instances AS i
      INNER JOIN workouts_exercises AS we ON i.workout_exercise_id = we.id
      INNER JOIN exercises AS e ON e.id = we.exercise_id
      WHERE we.workout_id = $1
      AND date(i.time_completed) = date(now())
      ORDER BY time_completed DESC;
    SQL
    results = query(sql, workout_id)
    
    results.map do |tuple|
      {
        id: tuple['id'],
        name: tuple['name'],
        workout_exercise_id: tuple['workout_exercise_id'],
        time_completed: tuple['time_completed'],
        completed_sets: tuple['completed_sets'],
        completed_reps: tuple['completed_reps'],
        lifted_weight: tuple['lifted_weight']
      }
    end
  end

  def add_set(params)
    workout_exercise_id = get_workout_exercise_id(params)

    sql = <<~SQL
      INSERT INTO instances (workout_exercise_id, completed_reps, lifted_weight)
      VALUES ($1, $2, $3);
    SQL
    query(sql, workout_exercise_id, params[:reps], params[:weight])
  end

  def get_workout_exercise_id(params)
    sql = 'SELECT id FROM workouts_exercises WHERE exercise_id = $1 AND workout_id = $2;'
    result = query(sql, params[:exercise_id], params[:workout_id])
    result.first['id']
  end

  def delete_instance(instance_id)
    sql = 'DELETE FROM instances WHERE id = $1'
    result = query(sql, instance_id)
  end

  def update_last_completed(workout_id)
    sql = 'UPDATE workouts SET last_completed = now() WHERE id = $1;'
    query(sql, workout_id)
  end

  private

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end
end
