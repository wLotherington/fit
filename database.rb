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

  def all_users
    # sql = 'SELECT * FROM users'
    # result = query(sql)
    
    # result.map do |tuple|
    #   { id: tuple['id'], name: tuple['name'] }
    # end
  end

  def get_user(username)
    sql = 'SELECT * FROM users WHERE name=$1'
    result = query(sql, username)

    {name: result.first['name'], id: result.first['id']}
  end

  def get_measurements(user_id)
    sql = 'SELECT * FROM measurements WHERE user_id=$1 ORDER BY day DESC'
    results = query(sql, user_id)

    results.map do |tuple|
      {
        id: tuple['id'],
        day: tuple['day'],
        user_id: tuple['user_id'],
        weight: tuple['weight'],
        body_fat: tuple['body_fat'],
      }
    end
  end

  def delete_measurement(id)
    sql = 'DELETE FROM measurements WHERE id=$1'
    query(sql, id)
  end

  def add_measurement(user_id, params)
    sql = 'INSERT INTO measurements (user_id, day, weight, body_fat) VALUES ($1, $2, $3, $4)'
    query(sql, user_id.to_i, params[:day], params[:weight].to_f, params[:body_fat].to_f)
  end

  private

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end
end
