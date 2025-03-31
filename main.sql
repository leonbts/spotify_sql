use spotify_db;

-- check data
select count(*) from audio_features;
select count(*) from sp_track;
select count(*) from sp_artist;
select count(*) from sp_artist_release;
select count(*) from sp_artist_track;
select count(*) from sp_release;

-- set indexes

ALTER TABLE sp_track MODIFY track_id VARCHAR(22);
CREATE INDEX idx_track_id ON sp_track(track_id);

DROP INDEX idx_track_id ON sp_artist_track;
SHOW INDEX FROM sp_artist_track;

SELECT 
    MAX(CHAR_LENGTH(track_id)) AS max_length
FROM sp_artist_track;

ALTER TABLE sp_artist_track MODIFY track_id VARCHAR(22);
CREATE INDEX idx_track_id ON sp_artist_track(track_id);

SELECT 
    MAX(CHAR_LENGTH(artist_id)) AS max_length
FROM sp_artist;
ALTER TABLE sp_artist MODIFY artist_id VARCHAR(22);
CREATE INDEX idx_artist_id ON sp_artist(artist_id);

SELECT 
    MAX(CHAR_LENGTH(release_id)) AS max_length
FROM sp_release;
ALTER TABLE sp_release MODIFY release_id VARCHAR(22);
CREATE INDEX idx_release_id ON sp_release(release_id);

ALTER TABLE sp_artist_release MODIFY artist_id VARCHAR(22);
ALTER TABLE sp_artist_release MODIFY release_id VARCHAR(22);
CREATE INDEX idx_artist_release ON sp_artist_release(artist_id, release_id);

ALTER TABLE sp_artist_track MODIFY artist_id VARCHAR(22);
ALTER TABLE sp_artist_track MODIFY track_id VARCHAR(22);
CREATE INDEX idx_artist_track ON sp_artist_track(artist_id, track_id);

SHOW INDEX FROM sp_artist_track;
DROP INDEX idx_track_id ON sp_artist_track;

SHOW INDEX FROM sp_artist_release;

-- check indexes
SHOW INDEX FROM audio_features; -- isrc
SHOW INDEX FROM sp_artist; -- artist_id
SHOW INDEX FROM sp_artist_release; -- 2 ind
SHOW INDEX FROM sp_artist_track;  -- 2 ind
SHOW INDEX FROM sp_release; -- release_id
SHOW INDEX FROM sp_track; -- track_id


ALTER TABLE sp_track MODIFY isrc VARCHAR(12);

ALTER TABLE audio_features
ADD PRIMARY KEY (isrc);

ALTER TABLE sp_artist
ADD PRIMARY KEY (artist_id);

ALTER TABLE sp_release
ADD PRIMARY KEY (release_id);

ALTER TABLE sp_track
ADD PRIMARY KEY (track_id);

ALTER TABLE sp_artist_release
ADD PRIMARY KEY (artist_id, release_id);

ALTER TABLE sp_artist_track
ADD PRIMARY KEY (artist_id, track_id);

ALTER TABLE sp_track
ADD CONSTRAINT fk_sp_track_audio_features
FOREIGN KEY (isrc) REFERENCES audio_features(isrc)
ON DELETE CASCADE
ON UPDATE CASCADE;

ALTER TABLE sp_artist_track
ADD CONSTRAINT fk_artist_track_track
FOREIGN KEY (track_id) REFERENCES sp_track(track_id)
ON DELETE CASCADE
ON UPDATE CASCADE;

-- try to create foreign key
ALTER TABLE sp_track
ADD CONSTRAINT fk_isrc
FOREIGN KEY (isrc) REFERENCES audio_features(isrc)
ON DELETE CASCADE
ON UPDATE CASCADE;


-- count how many tracks don't have a record in the audio_features: 142.650
SELECT count(isrc)
FROM sp_track
WHERE isrc NOT IN (SELECT isrc FROM audio_features);

-- there are 46 rows with nulls in isrc
SELECT *
FROM sp_track
WHERE isrc IS NULL;

-- we drop them
SET SQL_SAFE_UPDATES = 0; -- anables deleting rows

DELETE FROM sp_track
WHERE isrc IS NULL; -- 46 row(s) affected



-- create new rows in audio_features for isrc values that are in sp_track but doesn't exist in audio_features in order to connect the tables using
INSERT INTO audio_features (isrc, acousticness, danceability, duration_ms, energy, instrumentalness, `key`, liveness, loudness, mode, speechiness, tempo, time_signature, valence, updated_on)
SELECT DISTINCT sp.isrc, 
       NULL AS acousticness, 
       NULL AS danceability, 
       NULL AS duration_ms, 
       NULL AS energy, 
       NULL AS instrumentalness, 
       NULL AS `key`, 
       NULL AS liveness, 
       NULL AS loudness, 
       NULL AS mode, 
       NULL AS speechiness, 
       NULL AS tempo, 
       NULL AS time_signature, 
       NULL AS valence, 
       NULL AS updated_on
FROM sp_track sp
WHERE sp.isrc NOT IN (SELECT af.isrc FROM audio_features af); -- 129448 row(s) affected Records: 129448  Duplicates: 0  Warnings: 0


-- Создаем внешний ключ для sp_artist_release.release_id, указывающий на sp_release.release_id
ALTER TABLE sp_artist_release
ADD CONSTRAINT fk_release_id
FOREIGN KEY (release_id) REFERENCES sp_release(release_id)
ON DELETE CASCADE
ON UPDATE CASCADE;

-- Создаем внешний ключ для sp_artist_release.artist_id, указывающий на sp_artist.artist_id
ALTER TABLE sp_artist_release
ADD CONSTRAINT fk_artist_id
FOREIGN KEY (artist_id) REFERENCES sp_artist(artist_id)
ON DELETE CASCADE
ON UPDATE CASCADE;

ALTER TABLE sp_track
MODIFY COLUMN release_id VARCHAR(22);

ALTER TABLE sp_track
DROP FOREIGN KEY fk_release_id;


ALTER TABLE sp_track
ADD CONSTRAINT fk_release_id
FOREIGN KEY (release_id) REFERENCES sp_release(release_id)
ON DELETE CASCADE
ON UPDATE CASCADE;

ALTER TABLE sp_track
ADD CONSTRAINT fk_release_id_new
FOREIGN KEY (release_id) REFERENCES sp_release(release_id)
ON DELETE CASCADE
ON UPDATE CASCADE;



SELECT CONSTRAINT_NAME
FROM information_schema.REFERENTIAL_CONSTRAINTS
WHERE CONSTRAINT_SCHEMA = 'spotify_db' -- замените на имя вашей базы данных
AND TABLE_NAME = 'sp_track';

DESCRIBE sp_track;



SELECT CONSTRAINT_NAME, TABLE_NAME, COLUMN_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'spotify_db';


SHOW VARIABLES LIKE 'innodb_buffer_pool_size';
SELECT 
    table_schema AS "Database",
    ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS "Total Size (MB)"
FROM information_schema.tables
WHERE table_schema = 'spotify_db';



select 
	ar.artist_name
    , t.track_title 
    , t.duration_ms
    , fts.key
    , rl.popularity
    , DATE_FORMAT(CONVERT(rl.release_date,DATE), '%Y') AS release_year
    , DATE_FORMAT(CONVERT(rl.release_date,DATE), '%m') AS release_month
from sp_track t
	join audio_features fts
	using (isrc)
	join sp_artist_track artr
    using (track_id)
	join sp_artist ar
	using (artist_id)
    join sp_artist_release arrl
    on arrl.artist_id = ar.artist_id
    join sp_release rl
    on rl.release_id = arrl.release_id
;


select
     distinct rl.release_title 
    ,  ar.artist_name
    , rl.popularity
   , rl.release_date
    , DATE_FORMAT(CONVERT(rl.release_date,DATE), '%Y') AS release_year
from sp_track t
	join audio_features fts
	using (isrc)
	join sp_artist_track artr
    using (track_id)
	join sp_artist ar
	using (artist_id)
	join sp_artist_release arrl
    on arrl.artist_id = ar.artist_id
	join sp_release rl
    on rl.release_id = arrl.release_id
  --  WHERE t.isrc NOT IN (SELECT isrc FROM audio_features);
   where rl.popularity > 20
   order by popularity desc
    ;

select 
	distinct popularity
	, count(release_id) over(partition by popularity) 
    from sp_release
;


select
     distinct rl.release_title 
    ,  ar.artist_name
    , rl.popularity
   , rl.release_date
  , CASE
  WHEN CHAR_LENGTH(rl.release_date) = 4 -- if the date has just 4 digits, the year
  THEN rl.release_date 
  ELSE DATE_FORMAT(CONVERT(rl.release_date, DATE), '%Y') -- full date type
END AS release_year
   , DATE_FORMAT(CONVERT(rl.release_date,DATE), '%m') AS release_month
    
from sp_release rl
	join sp_artist_release arrl
    using(release_id)
    join sp_artist ar
	using (artist_id)
    where rl.popularity > 0
   order by popularity desc
    ;
    
    
    select count(*) from sp_release
    -- where total_tracks = 1
    ; -- 15.270 out of 713.563 releases have just 1 song
 
 
    -- 1. How changed Song duration through the years
    
    CREATE TABLE track_duration_summary AS
    with track_duration_year as
    (
		select
			t.track_id
			, round(t.duration_ms / 1000) as duration
			, CASE 
				WHEN CHAR_LENGTH(rl.release_date) = 4 THEN rl.release_date
				WHEN CHAR_LENGTH(rl.release_date) = 7 THEN SUBSTRING(rl.release_date, 1, 4)
				ELSE DATE_FORMAT(CONVERT(rl.release_date, DATE), '%Y')
			 END AS release_year  -- full date type
		from sp_track t
		join sp_release rl
		using (release_id)
    )
    SELECT 
		release_year
        , round(avg (duration)) as avg_duration
        , count(track_id) as num_of_tracks
	FROM track_duration_year
    GROUP BY release_year
    HAVING num_of_tracks > 1000 
    ORDER BY release_year
    ;
		
-- for tracks from popular releases

CREATE TABLE track_duration_summary_popular (
    release_year VARCHAR(4),
    avg_duration INT,
    num_of_tracks INT
);

INSERT INTO track_duration_summary_popular (release_year, avg_duration, num_of_tracks)
     with track_duration_year as
    (
		select
			t.track_id
			, round(t.duration_ms / 1000) as duration
			, CASE 
				WHEN CHAR_LENGTH(rl.release_date) = 4 THEN rl.release_date
				WHEN CHAR_LENGTH(rl.release_date) = 7 THEN SUBSTRING(rl.release_date, 1, 4)
				ELSE DATE_FORMAT(CONVERT(rl.release_date, DATE), '%Y')
        END AS release_year  
		from sp_track t
		join sp_release rl
		using (release_id)
        where rl.popularity > 0
    )
    SELECT 
		release_year
        , round(avg (duration)) as avg_duration
        , count(track_id) as num_of_tracks
	FROM track_duration_year
    GROUP BY release_year
    HAVING num_of_tracks > 1000 
    ORDER BY release_year
    ;       


-- distribution of loudness, speechiness, valence, danceability on popularity
CREATE TABLE loud_speech_valence_dance_vs_popularity AS
SELECT 
    rl.popularity,
    round(AVG(af.loudness), 3) AS avg_loudness,
    round(AVG(af.speechiness), 3) AS avg_speechiness,
    round(AVG(af.valence), 3) AS avg_valence,
    round(AVG(af.danceability), 3) AS avg_danceability
FROM sp_track t
JOIN audio_features af USING (isrc)
JOIN sp_release rl USING (release_id)
-- WHERE rl.popularity > 0
GROUP BY rl.popularity
ORDER BY rl.popularity
;


-- count avg number of artists per popular tracks through years
CREATE TABLE artists_pro_track_pop AS
select 
	 CAST(sub.release_year AS UNSIGNED) AS release_year
    , count(track_title) as num_of_tracks
    , avg(num_of_artists) as avg_num_of_artists
from 
(
select 
	distinct at.track_id
    , t.track_title
	, count(artist_id) over(partition by track_id) as num_of_artists
    , rl.popularity
    , CASE 
				WHEN CHAR_LENGTH(rl.release_date) = 4 THEN rl.release_date
				WHEN CHAR_LENGTH(rl.release_date) = 7 THEN SUBSTRING(rl.release_date, 1, 4)
				ELSE DATE_FORMAT(CONVERT(rl.release_date, DATE), '%Y')
                end as release_year 
from sp_artist_track at
join sp_track t
using (track_id)
join sp_release rl
using (release_id)
where rl.popularity > 0
) sub
group by release_year
having num_of_tracks > 5000
order by release_year
;

-- count avg number of artists per non-popular tracks through years
CREATE TABLE artists_pro_track_nonpop AS
select 
	 CAST(sub.release_year AS UNSIGNED) AS release_year
    , count(track_title) as num_of_tracks
    , avg(num_of_artists) as avg_num_of_artists
from 
(
select 
	distinct at.track_id
    , t.track_title
	, count(artist_id) over(partition by track_id) as num_of_artists
    , rl.popularity
    , CASE 
				WHEN CHAR_LENGTH(rl.release_date) = 4 THEN rl.release_date
				WHEN CHAR_LENGTH(rl.release_date) = 7 THEN SUBSTRING(rl.release_date, 1, 4)
				ELSE DATE_FORMAT(CONVERT(rl.release_date, DATE), '%Y')
                end as release_year 
from sp_artist_track at
join sp_track t
using (track_id)
join sp_release rl
using (release_id)
where rl.popularity = 0
) sub
group by release_year
having release_year > 1994
order by release_year
;

-- Leon's query
CREATE TABLE top_artists AS
SELECT a.artist_name, COUNT(t.track_id) AS song_count
FROM sp_artist_track at
JOIN sp_artist a ON at.artist_id = a.artist_id
JOIN sp_track t ON at.track_id = t.track_id
GROUP BY a.artist_name
ORDER BY song_count DESC
LIMIT 15;

CREATE TABLE top_artists_songs_top_popularity AS
SELECT a.artist_name, COUNT(t.track_id) AS song_count, max(rl.popularity) as top_popularity
FROM sp_artist_track at
JOIN sp_artist a ON at.artist_id = a.artist_id
JOIN sp_track t ON at.track_id = t.track_id
JOIN sp_release rl using (release_id)
GROUP BY a.artist_name
ORDER BY song_count DESC
LIMIT 20;

CREATE TABLE top_artists_songs_avg_popularity AS
SELECT a.artist_name, COUNT(t.track_id) AS song_count, avg(rl.popularity) as avg_popularity
FROM sp_artist_track at
JOIN sp_artist a ON at.artist_id = a.artist_id
JOIN sp_track t ON at.track_id = t.track_id
JOIN sp_release rl using (release_id)
GROUP BY a.artist_name
ORDER BY song_count DESC
LIMIT 20;


        
    -- -------------  experiments
    select * from audio_features;
    
    select * from audio_features;
    
    
    select 
		tr.track_title
		, ar.artist_name
    from
    sp_track tr
    join sp_artist_track artr
    using (track_id)
    join sp_artist ar
    using (artist_id)
    where ar.artist_name = "Elton John"
    ;