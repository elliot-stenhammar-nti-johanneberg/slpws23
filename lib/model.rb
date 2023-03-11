module Database
    DB = SQLite3::Database.new("db/database.db")
    DB.results_as_hash = true
    DB.execute("PRAGMA foreign_keys=ON")

    def get_all(table)
        sql = <<-SQL 
            SELECT * 
            FROM #{table}
        SQL
        return DB.execute(sql)
    end

    def get_filtered_albums(start_year, end_year, selected_genres, sort)
        if selected_genres.nil?
            sql = <<-SQL 
                SELECT albums.*, 
                    AVG(ratings.rating) AS avg_rating,
                    COUNT(ratings.rating) AS total_ratings
                FROM albums
                LEFT JOIN ratings ON albums.id = ratings.album_id
                WHERE albums.year BETWEEN #{start_year} AND #{end_year}
                GROUP BY albums.id
                ORDER BY 
                CASE "#{sort}"
                    WHEN "top" THEN avg_rating 
                    WHEN "popular" THEN total_ratings 
                    ELSE albums.title 
                END DESC
            SQL
        else 
            sql = <<-SQL 
                WITH RECURSIVE subgenres(id) AS (
                    SELECT id
                    FROM genres
                    WHERE id IN (#{selected_genres.join(", ")})
                    UNION ALL
                    SELECT g.id
                    FROM genres g
                    JOIN subgenres sg ON sg.id = g.parent_genre_id
                  ),
                  albums_with_ratings AS (
                    SELECT albums.*, 
                      AVG(ratings.rating) AS avg_rating,
                      COUNT(ratings.rating) AS total_ratings
                    FROM albums
                    LEFT JOIN ratings ON albums.id = ratings.album_id
                    JOIN album_genre_rel agr ON agr.album_id = albums.id
                    JOIN subgenres s ON s.id = agr.genre_id
                    WHERE albums.year BETWEEN #{start_year} AND #{end_year}
                        AND s.id IN (SELECT id FROM subgenres)
                    GROUP BY albums.id
                  )
                  SELECT DISTINCT a.*
                  FROM albums_with_ratings a
                  ORDER BY 
                    CASE ? 
                      WHEN 'top' THEN a.avg_rating 
                      WHEN 'popular' THEN a.total_ratings 
                      ELSE a.title 
                    END DESC
            SQL
        end
        return DB.execute(sql)
    end

    def get_album(id)
        sql = <<-SQL
            SELECT albums.*, artists.name 
            FROM albums 
                INNER JOIN artists ON albums.artist_id = artists.id 
            WHERE albums.id = ?
        SQL
        return DB.execute(sql, id).first
    end

    def get_album_genres(id)
        sql = <<-SQL
            SELECT genres.id, genres.name 
            FROM album_genre_rel 
                INNER JOIN genres ON album_genre_rel.genre_id = genres.id 
            WHERE album_genre_rel.album_id = ?
        SQL
        return DB.execute(sql, id)
    end

    def get_albums_genres(albums)
        album_ids = albums.map { |album| album["id"] }.join(", ")
        sql = <<-SQL
        SELECT genres.id, genres.name 
        FROM album_genre_rel 
            INNER JOIN genres ON album_genre_rel.genre_id = genres.id 
        WHERE album_genre_rel.album_id IN (#{album_ids})
        SQL
        return DB.execute(sql)      
    end

    def add_album(title, artist, year, genres)
        sql = <<-SQL
            INSERT INTO albums (title, artist_id, year) 
            VALUES (?, ?, ?)
        SQL
        DB.execute(sql, title, artist, year)
        
        album_id = DB.last_insert_row_id
        add_album_genre_rels(album_id, genres)
    end

    def add_album_genre_rels(album_id, genres)
        relations = genres.map { |genre| "(#{album_id}, #{genre})" }.join(", ")
        p relations
        sql = <<-SQL
            INSERT OR IGNORE INTO album_genre_rel (album_id, genre_id)
            VALUES #{relations}
        SQL
        DB.execute(sql)
    end

    def add_user(username, password_digest)
        sql = <<-SQL
            INSERT INTO users (username, password_digest) 
            VALUES (?, ?)
        SQL
        DB.execute(sql, username, password_digest)
    end

    def add_artist(name)
        sql = <<-SQL
            INSERT INTO artists (name) 
            VALUES (?)
        SQL
        DB.execute(sql, name)
    end

    def add_genre(name, parent_genre_id)
        sql = <<-SQL
            INSERT INTO genres (name, parent_genre_id)
            VALUES (?, ?)
        SQL
        DB.execute(sql, name, parent_genre_id)
    end

    def get_artist(id)
        sql = <<-SQL
            SELECT * 
            FROM artists 
            WHERE id = ?
        SQL
        return DB.execute(sql, id).first
    end

    def get_artist_albums(id)
        sql = <<-SQL
            SELECT * 
            FROM albums 
            WHERE artist_id = ?
        SQL
        return DB.execute(sql, id)
    end

    def update_album(id, title, artist, year, genres)
        sql = <<-SQL
            UPDATE albums 
            SET title = ?, artist_id = ?, year = ?
            WHERE id = ?
        SQL
        DB.execute(sql, title, artist, year, id)

        sql = <<-SQL
            DELETE FROM album_genre_rel
            WHERE album_id = ? AND genre_id NOT IN (#{genres.join(", ")})
        SQL
        DB.execute(sql, id)

        add_album_genre_rels(id, genres)
    end

    def update_artist(id, name)
        sql = <<-SQL
            UPDATE artists
            SET name = ?
            WHERE id = ? 
        SQL
        DB.execute(sql, name, id)
    end

    def get_user_by_username(username)
        return DB.execute("SELECT * FROM users WHERE username = ?", username).first
    end

    def delete_album(id)
        sql = <<-SQL
            DELETE FROM albums 
            WHERE id = ? 
        SQL
        DB.execute(sql, id)
    end

    def delete_artist(id)
        sql = <<-SQL
            DELETE FROM artists 
            WHERE id = ? 
        SQL
        DB.execute(sql, id)
    end

    def get_user_album_rating(user_id, album_id)
        sql = <<-SQL
            SELECT * 
            FROM ratings 
            WHERE user_id = #{user_id} AND album_id = #{album_id}  
        SQL
        DB.execute(sql).first
    end

    def add_rating(user_id, album_id, rating)
        sql = <<-SQL
            INSERT INTO ratings (user_id, album_id, rating) 
            VALUES (#{user_id}, #{album_id}, #{rating})
        SQL
        DB.execute(sql)
    end

    def update_rating(id, rating)
        sql = <<-SQL
            UPDATE ratings
            SET rating = #{rating}
            WHERE id = #{id}
        SQL
        DB.execute(sql)
    end

    def get_all_genres
        sql = <<-SQL 
            SELECT * 
            FROM genres
            ORDER BY name ASC
        SQL
    return DB.execute(sql)
    end
end

def if_permission_not(permission_level)
    if request.session[:user].nil? || request.session[:user]["permission"] < permission_level
        yield
    end
end