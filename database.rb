require 'pg'

class Database
  def initialize(logger)
    @db = if Sinatra::Base.production?
            PG.connect(ENV['DATABASE_URL'])
          else
            PG.connect(dbname: 'fitness')
          end
    @logger = logger
  end

  def disconnect
    @db.close
  end

  def all_users
    sql = 'SELECT * FROM users'
    result = query(sql)
    
    result.map do |tuple|
      { id: tuple['id'], name: tuple['name'] }
    end
  end

  def find_user(user_id)
    sql = 'SELECT * FROM users WHERE id = $1'
    result = query(sql, user_id)
    tuple = result.first

    { id: tuple['id'], name: tuple['name'] }
  end

  def create_user(user_name)
    sql = 'INSERT INTO users (name) VALUES ($1)'
    result = query(sql, user_name)
  end

  def health_stats_for(user_id)
    sql = 'SELECT * FROM health_stats WHERE user_id = $1 ORDER BY day'
    result = query(sql, user_id)

    result.map do |tuple|
      { id: tuple['id'], day: tuple['day'], weight: tuple['weight'], body_fat: tuple['body_fat'] }
    end
  end

  def workouts_for(user_id)
    sql = <<~SQL
      SELECT uw.id AS users_workouts_id, workouts.*
      FROM users_workouts AS uw
      INNER JOIN workouts ON workouts.id = uw.workout_id
      WHERE user_id = $1
    SQL
    result = query(sql, user_id)

    result.map do |tuple|
      { id: tuple['id'], name: tuple['name'], last_completed: tuple['last_completed'], last_trained: tuple['last_trained'], notes: tuple['notes'] }
    end
  end

  def create_health_stat(params)
    sql = <<~SQL
      INSERT INTO health_stats (day, weight, body_fat, user_id) VALUES
      ($1, $2, $3, $4)
    SQL
    result = query(sql, params[:day], params[:weight], params[:body_fat], params[:user_id])
  end

  def delete_health_stat(id)
    sql = 'DELETE FROM health_stats WHERE id = $1'
    result = query(sql, id)
  end

  def delete_user(id)
    sql = 'DELETE FROM users WHERE id = $1'
    result = query(sql, id)
  end

  private

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end
end
