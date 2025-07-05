create table goals (
GOAL_ID varchar,
MATCH_ID varchar,
PID varchar,
DURATION int,
ASSIST varchar,
GOAL_DESC varchar);

create table matches (
MATCH_ID varchar,
SEASON varchar,
DATE date,
HOME_TEAM varchar,
AWAY_TEAM varchar,
STADIUM varchar,HOME_TEAM_SCORE int, AWAY_TEAM_SCORE int, 
PENALTY_SHOOT_OUT int, ATTENDANCE int);

create table Players(
PLAYER_ID varchar,
FIRST_NAME varchar,
LAST_NAME varchar,
NATIONALITY varchar,
DOB date, TEAM varchar, JERSEY_NUMBER float, 
POSITION varchar,HEIGHT float, WEIGHT float, FOOT varchar);

create table teams(
TEAM_NAME varchar,
COUNTRY varchar,
HOME_STADIUM varchar);

create table Stadium (
Name varchar,
City varchar,
Country varchar,
Capacity int);

copy goals from 'C:\Program Files\PostgreSQL\16\datasql\goals.csv' CSV header;
copy matches from 'C:\Program Files\PostgreSQL\16\datasql\Matches.csv' CSV header;
copy Players from 'C:\Program Files\PostgreSQL\16\datasql\Players.csv' CSV header;
copy Stadium from 'C:\Program Files\PostgreSQL\16\datasql\Stadiums.csv' CSV header;
copy teams from 'C:\Program Files\PostgreSQL\16\datasql\Teams.csv' CSV header;


--- 1.Count the Total number of teams
SELECT COUNT(*) AS total_teams FROM Teams;

--- 2.Count the Total Number of teams per Country
SELECT country, COUNT(*) AS number_of_teams
FROM Teams
GROUP BY country
ORDER BY number_of_teams DESC;

--- 3.Calculate the Average Team name length
SELECT AVG(LENGTH(team_name)) AS avg_team_name_length
FROM Teams;

--- 4.Calculate the Average stadium capacity per country
SELECT country, ROUND(AVG(capacity)) AS avg_capacity, COUNT(*) AS total_stadiums
FROM Stadium
GROUP BY country
ORDER BY total_stadiums DESC;

--- 5.Calculate the Total goals scored
SELECT COUNT(*) AS total_goals FROM goals;

--- 6.Teams with 'City' in their name
SELECT COUNT(*) AS total_teams_with_city
FROM Teams
WHERE team_name LIKE '%City%';

--- 7.Concatenate Team name and country
SELECT CONCAT(team_name, ' (', country, ')') AS team_with_country
FROM Teams;

--- 8.Highest Attendance & match details
SELECT match_id, home_team, away_team, date, attendance
FROM Matches
ORDER BY attendance DESC
LIMIT 1;

--- 9.Lowest Attedance
SELECT match_id, home_team, away_team, date, attendance
FROM Matches
WHERE attendance > 1
ORDER BY attendance ASC
LIMIT 1;

--- 10. Match with the Highest Total score
SELECT match_id, home_team, away_team, (home_team_score + away_team_score) AS total_score
FROM Matches
ORDER BY total_score DESC
LIMIT 1;

--- 11.Goals scored by each team (Home & Away)
SELECT team_name,
       SUM(CASE WHEN home_team = team_name THEN home_team_score ELSE 0 END) +
       SUM(CASE WHEN away_team = team_name THEN away_team_score ELSE 0 END) AS total_goals
FROM Matches
JOIN Teams ON Matches.home_team = Teams.team_name OR Matches.away_team = Teams.team_name
GROUP BY team_name
ORDER BY (SUM(CASE WHEN home_team = team_name THEN home_team_score ELSE 0 END) +
          SUM(CASE WHEN away_team = team_name THEN away_team_score ELSE 0 END)) DESC;

--- 12.Rank teams by total goals in 'Old Trafford'
SELECT team_name,
       SUM(CASE WHEN home_team = team_name THEN home_team_score ELSE 0 END) + 
       SUM(CASE WHEN away_team = team_name THEN away_team_score ELSE 0 END) AS total_goals,
       RANK() OVER (ORDER BY SUM(CASE WHEN home_team = team_name THEN home_team_score ELSE 0 END) + 
                             SUM(CASE WHEN away_team = team_name THEN away_team_score ELSE 0 END) DESC) AS goal_rank
FROM Matches 
JOIN Teams ON Matches.home_team = Teams.team_name OR Matches.away_team = Teams.team_name
WHERE Matches.stadium = 'Old Trafford'
GROUP BY team_name
ORDER BY count(*) DESC;

--- 13.Top 5 players who scored the most goals in 'Old Trafford'
SELECT goals.pid, COUNT(*) AS total_goals
FROM Goals
JOIN Matches ON Goals.match_id = Matches.match_id
JOIN Stadium ON Matches.stadium = Stadium.name
WHERE Stadium.name = 'Old Trafford'
GROUP BY goals.pid
HAVING COUNT(*) > 0
ORDER BY total_goals DESC
LIMIT 5;

--- 14.List players and their total goals
SELECT pid, COUNT(*) AS total_goals
FROM Goals
GROUP BY pid
ORDER BY total_goals DESC
LIMIT 6;

--- 15.Identify the top scorer for each team
WITH PlayerGoals AS (
    SELECT
        p.player_id,
        p.first_name,
        p.last_name,
        p.team,
        COUNT(g.goal_id) AS total_goals,
        DENSE_RANK() OVER (PARTITION BY p.team ORDER BY COUNT(g.goal_id) DESC) AS dr
    FROM
        Players p
    LEFT JOIN  -- Use LEFT JOIN to include players with no goals
        Goals g ON p.player_id = g.pid
    GROUP BY
        p.player_id, p.first_name, p.last_name, p.team
)
SELECT
    pg.team,
    pg.first_name,
    pg.last_name,
    pg.total_goals
FROM
    PlayerGoals pg
WHERE
    pg.dr = 1;  -- Get all top scorers, even if tied


--- --- 16.Total goals in latest season
SELECT COUNT(*) AS total_goals_latest_season
FROM Goals
WHERE match_id IN(
      SELECT match_id FROM matches
	   WHERE season = (SELECT MAX(season) FROM matches)
);

--- 17.Matches with above average attedance
SELECT match_id, home_team, away_team, attendance
FROM Matches
WHERE attendance > (SELECT AVG(attendance) FROM Matches);

--- 18.Number of matches played each month
SELECT EXTRACT(MONTH FROM CAST(date as DATE)) AS month, COUNT(*) AS matches_played
FROM Matches
GROUP BY EXTRACT(MONTH FROM CAST(date as DATE))
ORDER BY month;
