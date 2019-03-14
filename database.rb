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

  def add_measurement(params)
    sql = 'INSERT INTO measurements (day, weight, body_fat) VALUES ($1, $2, $3)'
    query(sql, params[:day], params[:weight].to_f, params[:body_fat].to_f)
  end

  def delete_measurement(measurement_id)
    sql = 'DELETE FROM measurements WHERE id=$1'
    query(sql, measurement_id)
  end

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

  def get_all_workouts
    sql = 'SELECT * FROM workouts ORDER BY last_completed DESC'
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
      SELECT e.*, we.*, we.id AS workout_exercise_id, e.id AS exercise_id
      FROM exercises AS e
      INNER JOIN workouts_exercises AS we ON e.id = we.exercise_id
      WHERE we.workout_id = $1
      ORDER BY workout_exercise_id ASC;
    SQL
    results = query(sql, workout_id)
    
    results.map do |tuple|
      {
        id: tuple['exercise_id'],
        name: tuple['name'],
        time_created: tuple['time_created'],
        last_completed: tuple['last_completed'],
        workout_exercise_id: tuple['workout_exercise_id'],
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

  def delete_workout(workout_id)
    # select all workout_exercise_id's with the specified workout_id
    sql = 'SELECT id FROM workouts_exercises WHERE workout_id = $1'
    results = query(sql, workout_id)

    workout_exercise_ids = results.map do |tuple|
      tuple['id']
    end

    # update instnace table foreign key cosntraint
    workout_exercise_ids.each do |workout_exercise_id|
      sql = 'UPDATE instances SET workout_exercise_id = NULL where workout_exercise_id = $1'
      query(sql, workout_exercise_id)
    end

    # delete workout
    sql = 'DELETE FROM workouts WHERE id = $1'
    query(sql, workout_id)
  end

  def create_workout(workout_name)
    sql = 'INSERT INTO workouts (name) VALUES ($1)'
    query(sql, workout_name)
  end

  def get_largest_workout_id
    sql = 'SELECT id FROM workouts ORDER BY id DESC LIMIT 1'
    result = query(sql)
    workout_id = result.first['id']
    workout_id
  end

  def get_exercises
    sql = 'SELECT * FROM exercises ORDER BY time_created DESC'
    results = query(sql)

    results.map do |tuple|
      {
        id: tuple['id'],
        name: tuple['name'],
        time_created: tuple['time_created']
      }
    end
  end

  def delete_exercise(exercise_id)
    sql = 'DELETE FROM exercises WHERE id = $1'
    query(sql, exercise_id)
  end

  def create_exercise(params)
    # create exercise
    sql = 'INSERT INTO exercises (name) VALUES ($1)'
    query(sql, params[:exercise_name])

    # get exercise_id
    sql = 'SELECT id FROM exercises ORDER BY id DESC LIMIT 1'
    result = query(sql)
    exercise_id = result.first['id']

    # add workout_exercise
    sql = <<~SQL
      INSERT INTO workouts_exercises (workout_id, exercise_id, target_sets, target_reps, starting_weight)
      VALUES ($1, $2, $3, $4, $5)
    SQL
    query(sql, params[:workout_id], exercise_id, params[:sets], params[:reps], params[:weight])
  end

  def add_exercise(params)
    # get exercise_id
    sql = 'SELECT id FROM exercises WHERE name = $1'
    result = query(sql, params[:exercise_name])
    exercise_id = result.first['id']

    # add workout_exercise
    sql = <<~SQL
      INSERT INTO workouts_exercises (workout_id, exercise_id, target_sets, target_reps, starting_weight)
      VALUES ($1, $2, $3, $4, $5)
    SQL
    query(sql, params[:workout_id], exercise_id, params[:sets], params[:reps], params[:weight])
  end

  def get_manage_workout_exercises(workout_id)
    # select all workout_exercise_id's with the specified workout_id
    sql = 'SELECT id FROM workouts_exercises WHERE workout_id = $1'
    results = query(sql, workout_id)

    workout_exercise_ids = results.map do |tuple|
      tuple['id']
    end

    # update instnace table foreign key cosntraint
    workout_exercise_ids.each do |workout_exercise_id|
      sql = 'UPDATE instances SET workout_exercise_id = NULL where workout_exercise_id = $1'
      query(sql, workout_exercise_id)
    end

    # delete workout_exercise
    sql = <<~SQL
      SELECT *, we.id AS workout_exercise_id FROM exercises AS e
      INNER JOIN workouts_exercises AS we ON we.exercise_id = e.id
      WHERE we.workout_id = $1
      ORDER BY workout_exercise_id ASC
    SQL
    results = query(sql, workout_id)

    results.map do |tuple|
      {
        workout_exercise_id: tuple['workout_exercise_id'],
        name: tuple['name'],
        sets: tuple['target_sets'],
        reps: tuple['target_reps'],
        weight: tuple['starting_weight'],
        time_created: tuple['time_created']
      }
    end
  end

  def toggle_workout(workout_id, state)
    sql = 'UPDATE workouts SET active = $1 WHERE id = $2'
    query(sql, state, workout_id)
  end

  def delete_workout_exercise(workout_exercise_id)
    sql = 'DELETE FROM workouts_exercises WHERE id = $1'
    query(sql, workout_exercise_id)
  end

  def last_weight(workout_exercise_id)
    sql = <<~SQL
      SELECT SUM(completed_reps * lifted_weight) AS total_weight, time_completed::date AS date_completed
      FROM instances
      WHERE workout_exercise_id = $1
      AND time_completed::date != date(now())
      GROUP BY date_completed
      ORDER BY date_completed DESC LIMIT 1;
    SQL
    result = query(sql, workout_exercise_id)

    return result.first['total_weight'] unless result.first.nil?
    false
  end

  def get_progress
    sql = <<~SQL
      SELECT i.time_completed, i.completed_reps, i.lifted_weight, e.name
      FROM instances AS i
      INNER JOIN workouts_exercises AS we ON we.id = i.workout_exercise_id
      INNER JOIN exercises AS e ON e.id = we.exercise_id
      ORDER BY time_completed DESC;
    SQL
    results = query(sql)

    results.map do |tuple|
      {
        time_completed: tuple['time_completed'],
        completed_reps: tuple['completed_reps'],
        lifted_weight: tuple['lifted_weight'],
        exercise_name: tuple['name']
      }
    end
  end

  private

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end
end
