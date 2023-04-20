module Database
    # Create a connection to database
    DB = SQLite3::Database.new("db/database.db")
    # Set results_as_hash as true
    DB.results_as_hash = true
    # Enable foreign_keys
    DB.execute("PRAGMA foreign_keys=ON")

    # Get all columns of a table
    #
    # @param table [String] Table name
    #
    # @return [Array<Hash>] Array of hashes where each hash represents a row in table, with columns as keys
    def get_all(table)
        sql = <<-SQL 
            SELECT * 
            FROM #{table}
        SQL
        return DB.execute(sql)
    end

    # Get albums albums which pass filter
    #
    # @param start_year [Integer] Start year
    # @param end_year [Integer] End year
    # @param selected_genres [Array<Integer>] Array of genre ids
    # @param sort [String] Sort type ("top" or "popular")
    #
    # @return [Array<Hash>]
    #   * "id" [String] Album id
    #   * "title" [String] Album title
    def get_filtered_albums(start_year, end_year, selected_genres, sort)
        if selected_genres.nil?
            sql = <<-SQL 
                SELECT albums.title, albums.id, 
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
                  SELECT DISTINCT a.title
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

    # Get an album (joined with artist name) by id
    #
    # @param id [integer] Album id 
    #
    # @return [Array<Hash>]
    #   * "id" [Integer] Album id 
    #   * "year" [Integer] Year published
    #   * "title" [String] Album title
    #   * "artists_id" [Integer] Associated artist's id
    #   * "name" [String] Associated artist's name
    def get_album(id)
        sql = <<-SQL
            SELECT albums.*, artists.name 
            FROM albums 
                INNER JOIN artists ON albums.artist_id = artists.id 
            WHERE albums.id = ?
        SQL
        return DB.execute(sql, id).first
    end

    # Gets genres associated with an album
    # 
    # @param id [Integer] the ID of the album to retrieve genres for
    # @return [Array<Hash>]
    #   * "id" [Integer] Genre id 
    #   * "name" [String] Genre name
    def get_album_genres(id)
        sql = <<-SQL
            SELECT genres.id, genres.name 
            FROM album_genre_rel 
                INNER JOIN genres ON album_genre_rel.genre_id = genres.id 
            WHERE album_genre_rel.album_id = ?
        SQL
        return DB.execute(sql, id)
    end

    # gets genres for the specified albums
    # 
    # @param albums [Array<Hash>] an array of album hashes with an "id" key.
    # @return [Array<Hash>]
    #   * "id" [Integer] Genre id 
    #   * "name" [String] Genre name
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

    # Creates new album
    # 
    # @param title [String] Album title
    # @param artist [String] Artist id
    # @param year [Integer] Year published
    # @param genres [Array<Integer>] Genre ids
    def add_album(title, artist, year, genres)
        sql = <<-SQL
            INSERT INTO albums (title, artist_id, year) 
            VALUES (?, ?, ?)
        SQL
        DB.execute(sql, title, artist, year)
        
        album_id = DB.last_insert_row_id
        add_album_genre_rels(album_id, genres)
    end

    # Creates album genre relations
    # 
    # @param album_id [Integer] Album id
    # @param genres [Array<Integer>] Genre ids
    def add_album_genre_rels(album_id, genres)
        relations = genres.map { |genre| "(#{album_id}, #{genre})" }.join(", ")
        p relations
        sql = <<-SQL
            INSERT OR IGNORE INTO album_genre_rel (album_id, genre_id)
            VALUES #{relations}
        SQL
        DB.execute(sql)
    end

    # Creates new user
    # 
    # @param username [String] Username
    # @param password_digest [String] Hashed password
    def add_user(username, password_digest)
        sql = <<-SQL
            INSERT INTO users (username, password_digest) 
            VALUES (?, ?)
        SQL
        DB.execute(sql, username, password_digest)
    end

    # Creates new artist
    # 
    # @param name [String] Artist name
    def add_artist(name)
        sql = <<-SQL
            INSERT INTO artists (name) 
            VALUES (?)
        SQL
        DB.execute(sql, name)
    end

    # Creates new genre
    # 
    # @param name [String] Username
    # @param parent_genre_id [Integer] Genre's parent genre (Or NULL)
    def add_genre(name, parent_genre_id)
        sql = <<-SQL
            INSERT INTO genres (name, parent_genre_id)
            VALUES (?, ?)
        SQL
        DB.execute("PRAGMA defer_foreign_keys=ON;") # NOt working correctly
        DB.execute(sql, name, parent_genre_id)
    end

    # Get artist row by id
    # 
    # @param id [String] Artist id
    # @return [Array<Hash>]
    #   * "id" [Integer] Artist id 
    #   * "name" [String] Artist name
    def get_artist(id)
        sql = <<-SQL
            SELECT * 
            FROM artists 
            WHERE id = ?
        SQL
        return DB.execute(sql, id).first
    end

    # Get albums by artist
    # 
    # @param id [Integer] Artist id
    # @return [Array<Hash>]
    #   * "id" [String] Album id
    #   * "title" [String] Album title
    def get_artist_albums(id)
        sql = <<-SQL
            SELECT id, title
            FROM albums 
            WHERE artist_id = ?
        SQL
        return DB.execute(sql, id)
    end

    # Update album details by id
    # 
    # @param id [Integer] Album id
    # @param title [String] Album title
    # @param artist [Integer] Artist id
    # @param year [Integer] Year published
    # @param genres [Array<Integer>] Genre ids
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

    # Update aritst details(name) by id
    # 
    # @param id [Integer] Artist id
    # @param name [String] Artist name
    def update_artist(id, name)
        sql = <<-SQL
            UPDATE artists
            SET name = ?
            WHERE id = ? 
        SQL
        DB.execute(sql, name, id)
    end

    # Get user by username
    # 
    # @param username [String] Username
    # @return [Array<Hash>]
    #   * "id" [Integer] User's id
    #   * "username" [String] User's username
    #   * "password_digest" [String] User's hashed password
    #   * "permission" [Integer] User's permission level
    def get_user_by_username(username)
        sql = <<-SQL
            SELECT *
            FROM users 
            WHERE username = ?
        SQL
        return DB.execute(sql, username).first
    end

    # Deletes album by id
    # 
    # @param id [Integer] Album id
    def delete_album(id)
        sql = <<-SQL
            DELETE FROM albums 
            WHERE id = ? 
        SQL
        DB.execute(sql, id)
    end

    # Deletes artist by id
    # 
    # @param id [Integer] Artist id
    def delete_artist(id)
        sql = <<-SQL
            DELETE FROM artists 
            WHERE id = ? 
        SQL
        DB.execute(sql, id)
    end

    # Gets rating by album id and user id
    # 
    # @param user_id [Integer] User id
    # @param album_id [Integer] Album id
    # @return [Array<Hash>]
    #   * "id" [Integer] Rating id
    #   * "user_id" [Integer] Rating's user id
    #   * "album_id" [Integer] Rating's album id
    #   * "rating" [Integer] Rating value
    def get_user_album_rating(user_id, album_id)
        sql = <<-SQL
            SELECT * 
            FROM ratings 
            WHERE user_id = #{user_id} AND album_id = #{album_id}  
        SQL
        DB.execute(sql).first
    end

    # Creates new rating
    # 
    # @param user_id [Integer] User id
    # @param album_id [Integer] Album id
    # @param rating [Integer] Rating value
    def add_rating(user_id, album_id, rating)
        sql = <<-SQL
            INSERT INTO ratings (user_id, album_id, rating) 
            VALUES (#{user_id}, #{album_id}, #{rating})
        SQL
        DB.execute(sql)
    end

    # Updates rating by id
    # 
    # @param id [Integer] User id
    # @param rating [Integer] Rating value
    def update_rating(id, rating)
        sql = <<-SQL
            UPDATE ratings
            SET rating = ?
            WHERE id = ?, user_id = ?
        SQL
        DB.execute(sql, rating, id, session[:user]["id"])
    end

    # Gets all genres sorted alphabetically
    # 
    # @return [Array<Hash>]
    #   * "id" [Integer] Genre id
    #   * "name" [Integer] Genre name
    #   * "parent_genre_id" [Integer] Genre's parent genre id
    def get_all_genres
        sql = <<-SQL 
            SELECT * 
            FROM genres
            ORDER BY name ASC
        SQL
        return DB.execute(sql)
    end

    # Gets average rating value of album by id
    #
    # @param id [Integer] User id
    # @return [Integer] Average rating
    def get_album_rating_avg(id)
        sql = <<-SQL 
            SELECT AVG(rating) 
            FROM ratings
            WHERE album_id = #{id}
        SQL
        return DB.execute(sql).first
    end

    def update_user(username, password)
        if password.empty?
            sql = <<-SQL 
                UPDATE users
                SET username = ?
                WHERE id = ?
            SQL
            DB.execute(sql, username, session[:user]["id"])
        else 
            sql = <<-SQL 
                UPDATE users
                SET username = ?, password_digest = ?
                WHERE id = ?
            SQL
            DB.execute(sql, username, BCrypt::Password.create(password), session[:user]["id"])
        end
    end

    def get_ratings_by_user_id(id)
        sql = <<-SQL 
            SELECT ratings.*, albums.title
            FROM ratings
                INNER JOIN albums ON albums.id = ratings.album_id 
            WHERE user_id = ?
        SQL
        return DB.execute(sql, id)
    end
end

module Helper
    
    # Checks if user's permission level exceeds threshold and if not executes yield function 
    #
    # @param permission_level [Integer] Permission threshold 
    # @yield [Block] Funciton to execute if permission not granted
    def if_permission_not(permission_level)
    if request.session[:user].nil? || request.session[:user]["permission"] < permission_level
        yield
    end
    end

    def logged_in?()
        return !session[:user].nil?
    end
end