def open_db(hash: false)
    db = SQLite3::Database.new("db/database.db")
    if :hash
        db.results_as_hash = true
    end
    yield db
end

def get_filtered_albums(start_year, end_year, selected_genres)
    open_db(hash: true) { |db|
        if selected_genres.nil?
            sql = <<-SQL 
                SELECT * FROM albums 
                WHERE year BETWEEN ? AND ?
            SQL
        else 
            sql = <<-SQL 
                SELECT albums.id, albums.title, albums.artist_id, albums.year, genres.name 
                FROM albums 
                    JOIN album_genre_rel ON albums.id = album_genre_rel.album_id 
                    JOIN genres ON album_genre_rel.genre_id = genres.id 
                WHERE albums.year 
                    BETWEEN ? AND ? 
                    AND genres.id IN (#{selected_genres.join(", ")}) 
                GROUP BY albums.id 
                HAVING COUNT(DISTINCT genres.id) = #{selected_genres.length}
            SQL
        end
        albums = db.execute(sql, start_year, end_year)
        return albums
    }
end

def get_all(table)
    open_db(hash: true) { |db|
        return db.execute("SELECT * FROM #{table}")
    }
end