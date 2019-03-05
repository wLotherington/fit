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

  def delete_measurement(id)
    sql = 'DELETE FROM measurements WHERE id=$1'
    query(sql, id)
  end

  def get_workouts
    sql = 'SELECT * FROM workouts ORDER BY day_created DESC'
    results = query(sql)

    results.map do |tuple|
      {
        id: tuple['id'],
        name: tuple['name'],
        day_created: tuple['day_created'],
        last_completed: tuple['creator_id'],
        active: tuple['active'],
      }
    end
  end

  def get_workout(id)
    sql = 'SELECT * FROM workouts WHERE id = $1'
    result = query(sql, id)
    tuple = result.first
    
    {
      id: tuple['id'],
      name: tuple['name'],
      day_created: tuple['day_created'],
      last_completed: tuple['creator_id'],
      active: tuple['active'],
    }
  end

  def get_exercises
    sql = 'SELECT * FROM exercises ORDER BY id DESC'
    results = query(sql)

    results.map do |tuple|
      {
        id: tuple['id'],
        name: tuple['name'],
        sets: tuple['sets'],
        reps: tuple['reps'],
        weight: tuple['weight']
      }
    end
  end

  def create_workout(params)
    sql = 'INSERT INTO workouts (name, active) VALUES ($1, $2)'
    query(sql, params[:name], !!params[:active])
  end

  def get_workout_id(params)
    sql = 'SELECT id FROM workouts WHERE name = $1 ORDER BY id DESC LIMIT 1'
    result = query(sql, params[:name])

    result.first['id']
  end

  def delete_workout(id)
    sql = 'DELETE FROM workouts WHERE id=$1'
    query(sql, id)
  end

  private

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end
end
