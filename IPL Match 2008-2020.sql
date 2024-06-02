CREATE TABLE IPL_Ball (
    id INT,
    inning INT,
    over INT,
    ball INT,
    batsman VARCHAR(255),
    non_striker VARCHAR(255),
    bowler VARCHAR(255),
    batsman_runs INT,
    extra_runs INT,
    total_runs INT,
    is_wicket INT,
    dismissal_kind VARCHAR(255),
    player_dismissed VARCHAR(255),
    fielder VARCHAR(255),
    extras_type VARCHAR(255),
    batting_team VARCHAR(255),
    bowling_team VARCHAR(255));

COPY IPL_Ball FROM 'S:\1.Study Folder\DATA Analyst\Internshala\SQL\Final Project\IPL Dataset\IPL Dataset\IPL_Ball.csv' DELIMITER ',' CSV HEADER;

DROP TABLE IPL_Ball;


CREATE TABLE IPL_Matches (
    id INT,
    city VARCHAR(255),
    date DATE,
    player_of_match VARCHAR(255),
    venue VARCHAR(255),
    neutral_venue BOOLEAN,
    team1 VARCHAR(255),
    team2 VARCHAR(255),
    toss_winner VARCHAR(255),
    toss_decision VARCHAR(50),
    winner VARCHAR(255),
    result VARCHAR(50),
    result_margin VARCHAR(255),
    eliminator BOOLEAN,
    method VARCHAR(50),
    umpire1 VARCHAR(255),
    umpire2 VARCHAR(255)
);

ALTER TABLE IPL_Matches Alter column neutral_venue TYPE VARCHAR(50);
ALTER TABLE IPL_Matches Alter column eliminator TYPE VARCHAR(50);
ALTER TABLE IPL_Matches ALTER COLUMN result_margin TYPE INT USING result_margin::integer;

COPY IPL_Matches FROM 'S:\1.Study Folder\DATA Analyst\Internshala\SQL\Final Project\IPL Dataset\IPL Dataset\IPL_matches.csv' CSV HEADER;

SELECT * FROM ipl_ball;
SELECT * FROM ipl_matches;

/* "Aggressive batsmen" */
 
SELECT  batsman AS "Aggressive batsmen",
        total_runs,
        balls_faced,
        ROUND(total_runs * 100.0 
			  / NULLIF(balls_faced, 0), 2) AS strike_rate
FROM ( SELECT 
        batsman,
        SUM(CASE WHEN extras_type != 'wides' 
			THEN batsman_runs ELSE total_runs END) AS total_runs,
        COUNT(CASE WHEN extras_type != 'wides' 
			  THEN ball ELSE NULL END) AS balls_faced
       FROM IPL_Ball
       GROUP BY batsman
       HAVING  COUNT(CASE WHEN extras_type != 'wides' 
					 THEN ball ELSE NULL END) >= 500)
ORDER BY strike_rate DESC
LIMIT 10;

/* "Anchor Batsmen" */

SELECT * FROM ipl_ball;

SELECT ball.batsman, EXTRACT(year from match.date) AS IPL_year, COUNT(DISTINCT match.ID) AS "No of Match"
FROM ipl_ball AS ball 
LEFT JOIN ipl_matches AS match ON ball.id=match.id 
GROUP BY ball.batsman, EXTRACT(year from match.date) Order by "No of Match" DESC
limit 100;
--Final Answer
SELECT *,
       CASE WHEN dismissals > 0 
	   THEN ROUND(CAST(total_runs AS DECIMAL) / dismissals, 2) 
	   ELSE 0 END AS batting_average
FROM (SELECT batsman AS "Anchor Batsmen", 
       COUNT(IPL_year) AS "IPL_season_played", 
       SUM("total runs") AS total_runs,
	   SUM(dismissals) AS dismissals
      FROM (SELECT ball.batsman, 
                   EXTRACT(year FROM match.date) AS IPL_year, 
                   SUM(ball.total_runs) AS "total runs",
                   SUM(CASE WHEN ball.is_wicket=1 
					   THEN 1 ELSE 0 END) AS dismissals
          FROM ipl_ball AS ball 
          LEFT JOIN ipl_matches AS match ON ball.id = match.id 
          GROUP BY ball.batsman, EXTRACT(year FROM match.date)
	      HAVING SUM(CASE WHEN ball.is_wicket=1 
					 THEN 1 ELSE 0 END) > 0) AS subquery
    GROUP BY batsman
    HAVING COUNT(IPL_year) > 2) AS subquery
ORDER BY batting_average DESC
LIMIT 10;


/* "Hard-hitting players" */


SELECT "Hard-hitting players",
		COUNT(IPL_year) AS "No of IPL_season_played",
		SUM ("Total Boundaries 4Run") AS "Total Boundaries 4Run",
		SUM ("Total Boundaries 6Run") AS "Total Boundaries 6Run",
		SUM ("Total Boundaries Run") AS "Total Boundaries Run"
FROM (SELECT ball.batsman AS "Hard-hitting players",
	   EXTRACT(year FROM match.date) AS IPL_year,
       SUM(CASE WHEN ball.batsman_runs = 4 THEN 4 ELSE 0 END) AS "Total Boundaries 4Run",
       SUM(CASE WHEN ball.batsman_runs = 6 THEN 6 ELSE 0 END) AS "Total Boundaries 6Run",
       SUM(CASE WHEN ball.batsman_runs = 4 THEN 4 ELSE 0 END +
           CASE WHEN ball.batsman_runs = 6 THEN 6 ELSE 0 END) AS "Total Boundaries Run"
      FROM ipl_ball AS ball 
          LEFT JOIN ipl_matches AS match ON ball.id = match.id 
          GROUP BY ball.batsman, EXTRACT(year FROM match.date))
GROUP BY "Hard-hitting players"
HAVING COUNT(IPL_year) >= 2
ORDER BY "Total Boundaries Run" DESC LIMIT 10;

SELECT batsman AS "Hard-hitting player",
       COUNT(DISTINCT EXTRACT(year FROM match.date)) AS "IPL seasons played",
       SUM(CASE WHEN ball.batsman_runs = 4 
		   THEN 4 ELSE 0 END) AS "Total boundaries 4s",
       SUM(CASE WHEN ball.batsman_runs = 6 
		   THEN 6 ELSE 0 END) AS "Total boundaries 6s",
       SUM(CASE WHEN ball.batsman_runs IN (4, 6) 
		   THEN ball.batsman_runs ELSE 0 END) AS "Total boundaries runs",
       ROUND(SUM(CASE WHEN ball.batsman_runs IN (4, 6) 
				 THEN ball.batsman_runs ELSE 0 END) * 100.0 
			 / NULLIF(SUM(ball.total_runs), 0), 2) AS "Boundary percentage"
FROM ipl_ball AS ball
LEFT JOIN ipl_matches AS match ON ball.id = match.id
GROUP BY batsman
HAVING COUNT(DISTINCT EXTRACT(year FROM match.date)) >= 2
ORDER BY "Total boundaries runs" DESC
LIMIT 10;

--Final Answer
SELECT batsman AS "Hard-hitting player",
       COUNT(DISTINCT EXTRACT(year FROM match.date)) 
	   			AS "IPL seasons played",
       SUM(CASE WHEN ball.batsman_runs IN (4, 6) 
		   THEN ball.batsman_runs ELSE 0 END) 
		   		AS "Total boundaries runs",
	   SUM(ball.total_runs) AS "Total runs",
       ROUND(SUM(CASE WHEN ball.batsman_runs IN (4, 6) 
				 THEN ball.batsman_runs ELSE 0 END) * 100.0 
			 / NULLIF(SUM(ball.total_runs), 0), 2) 
			 	AS "Boundary percentage"
FROM ipl_ball AS ball
LEFT JOIN ipl_matches AS match ON ball.id = match.id
GROUP BY batsman
HAVING COUNT(DISTINCT EXTRACT(year FROM match.date)) > 2
ORDER BY "Total boundaries runs" DESC
LIMIT 10;

SELECT batsman AS "Hard-hitting player", -- Selecting the batsman's name as "Hard-hitting player".
       COUNT(DISTINCT EXTRACT(year FROM match.date)) AS "No of IPL seasons played", -- Counting the distinct IPL seasons played by the batsman.
       SUM(CASE WHEN ball.batsman_runs = 4 THEN 4 ELSE 0 END) AS "Total boundaries 4s", -- Summing up the number of boundaries (4s) hit by the batsman.
       SUM(CASE WHEN ball.batsman_runs = 6 THEN 6 ELSE 0 END) AS "Total boundaries 6s", -- Summing up the number of boundaries (6s) hit by the batsman.
       SUM(CASE WHEN ball.batsman_runs IN (4, 6) THEN ball.batsman_runs ELSE 0 END) AS "Total boundaries runs", -- Summing up the total runs scored in boundaries by the batsman.
       ROUND(SUM(CASE WHEN ball.batsman_runs IN (4, 6) THEN ball.batsman_runs ELSE 0 END) * 100.0 / NULLIF(SUM(ball.total_runs), 0), 2) AS "Boundary percentage" -- Calculating the boundary percentage scored by the batsman.
FROM ipl_ball AS ball -- From the ipl_ball table aliased as ball.
LEFT JOIN ipl_matches AS match ON ball.id = match.id -- Left joining with the ipl_matches table aliased as match based on the match id.
GROUP BY batsman -- Grouping the results by batsman.
HAVING COUNT(DISTINCT EXTRACT(year FROM match.date)) >= 2 -- Filtering the results to include only batsmen who have played in at least 2 IPL seasons.
ORDER BY "Total boundaries runs" DESC -- Ordering the results by total runs scored in boundaries in descending order.
LIMIT 10; -- Limiting the results to the top 10 players.

/* bowlers with good economy */

SELECT bowler AS "Good Economy Bowler", 
       SUM(CASE WHEN extras_type IN ('byes', 'legbyes') 
		   THEN batsman_runs ELSE total_runs END) 
		   		AS "Total Runs Conceded",
       CEIL(COUNT(bowler) / 6.0) AS "Total Overs Bowled",
       ROUND(SUM(CASE WHEN extras_type IN ('byes', 'legbyes') 
				 THEN batsman_runs ELSE total_runs END) /
           (COUNT(bowler) / 6.0),3)	 AS "Economy"
FROM ipl_ball
GROUP BY bowler
HAVING COUNT(bowler) >= 500
ORDER BY "Economy" DESC
LIMIT 10;

SELECT bowler AS "Economy Bowler", -- Selecting the bowler's name as "Economy Bowler"
       SUM(CASE WHEN extras_type IN ('byes', 'legbyes') -- Summing total runs conceded by bowler, considering extras
		   THEN batsman_runs ELSE total_runs END) AS "Total Runs Conceded", -- Conditional sum
       CEIL(COUNT(bowler) / 6.0) AS "Total Overs Bowled", -- Calculating total overs bowled (ceiling value for each 6 balls)
       ROUND(SUM(CASE WHEN extras_type IN ('byes', 'legbyes') -- Calculating economy rate of the bowler
				 THEN batsman_runs ELSE total_runs END) /
           (COUNT(bowler) / 6.0), 3) AS "Economy" -- Dividing total runs conceded by total overs bowled, rounding to 3 decimal places
FROM ipl_ball -- From the ipl_ball table
GROUP BY bowler -- Grouping results by bowler
HAVING COUNT(bowler) >= 500 -- Considering only bowlers who have bowled at least 500 balls
ORDER BY "Economy" DESC -- Ordering results by economy rate in descending order
LIMIT 10; -- Limiting the output to 10 rows

/* bowlers with the best strike rate */

SELECT bowler AS "Best Strike Rate Bowler", 
       COUNT(bowler) AS "number of balls bowled",
	   SUM(is_wicket) AS "Total Wickets Taken",
	   ROUND(COUNT(bowler)*1.00
			 /NULLIF(SUM(is_wicket),0),2) AS "Strike Rate"
	FROM ipl_ball
	WHERE NOT dismissal_kind 
		  IN('run out','retired hurt','obstucting the field')
	GROUP BY bowler
HAVING COUNT(bowler) > 500
ORDER BY "Strike Rate" DESC
LIMIT 10;

SELECT bowler AS "Strike Rate Bowler", -- Selecting the bowler's name as "Strike Rate Bowler"
       COUNT(*) AS "Total Balls Bowled", -- Counting total balls bowled by the bowler
       SUM(CASE WHEN is_wicket = 1 THEN 1 ELSE 0 END) AS "Total Wickets Taken", -- Summing total wickets taken by the bowler
       ROUND(COUNT(*)::numeric / NULLIF(SUM(CASE WHEN is_wicket = 1 THEN 1 ELSE 0 END), 0), 2) AS "Strike Rate" -- Calculating strike rate of the bowler (balls bowled / wickets taken), rounding to 2 decimal places
FROM IPL_Ball -- From the IPL_Ball table
WHERE NOT dismissal_kind IN('run out','retired hurt','obstucting the field')
GROUP BY bowler -- Grouping results by bowler
HAVING COUNT(*) >= 500 -- Considering only bowlers who have bowled at least 500 balls
ORDER BY "Strike Rate" DESC -- Ordering results by strike rate in ascending order
LIMIT 10; -- Limiting the output to 10 rows

/* ALL Rounder */

SELECT BattingStats.player AS "All-Rounder",
	   BattingStats.balls_faced AS "Balls Faced",
	   BattingStats.total_runs AS "Total Runs Scored",
	   BattingStats.batting_strike_rate AS "Batting Strike Rate",
	   BowlingStats.balls_bowled AS "Balls Bowled",
	   BowlingStats.total_wickets AS "Total Wickets Taken",
	   BowlingStats.bowling_strike_rate AS "Bowling Strike Rate"
FROM ( SELECT batsman AS player,
	 		  COUNT(CASE WHEN extras_type != 'wides' THEN ball ELSE NULL END) AS balls_faced,
	 		  SUM(CASE WHEN extras_type != 'wides' THEN batsman_runs ELSE total_runs END) AS total_runs,
	 		  ROUND(SUM(CASE WHEN extras_type != 'wides' THEN batsman_runs ELSE total_runs END)* 100.0 
					/ NULLIF(COUNT(CASE WHEN extras_type != 'wides' THEN ball ELSE NULL END), 0), 2) 
	  				AS batting_strike_rate
	   FROM ipl_ball
	   GROUP BY batsman
	   HAVING COUNT(CASE WHEN extras_type != 'wides' THEN ball ELSE NULL END)>500) AS BattingStats
JOIN ( SELECT bowler AS player, 
       		  COUNT(bowler) AS balls_bowled,
	   		  SUM(is_wicket) AS total_wickets,
	   		  ROUND(COUNT(bowler)*1.00/NULLIF(SUM(is_wicket),0),2) AS bowling_strike_rate
	   FROM ipl_ball
	   WHERE NOT dismissal_kind IN('run out','retired hurt','obstucting the field')
	   GROUP BY bowler
       HAVING COUNT(bowler) > 500) AS BowlingStats
ON BattingStats.player = BowlingStats.player
-- Ordering results by the average of batting and bowling strike rates in descending order
ORDER BY (BattingStats.batting_strike_rate + BowlingStats.bowling_strike_rate) / 2 DESC 
LIMIT 10;

/* Wicketkeeper */

SELECT batsman As player
	   SUM(CASE WHEN B.extras_type != 'wides' THEN B.batsman_runs ELSE B.total_runs END) AS total_runs,
       ROUND(SUM(CASE WHEN B.extras_type != 'wides' THEN B.batsman_runs ELSE B.total_runs END)* 100.0 
					/ NULLIF(COUNT(CASE WHEN B.extras_type != 'wides' THEN B.ball ELSE NULL END), 0), 2) 
	  				AS batting_strike_rate,
SELECT fielder AS wicketkeeper,
		COUNT(CASE WHEN dismissal_kind IN ('caught', 'stumped') THEN 1 END) AS catches_stumpings,
		SUM(CASE WHEN extras_type != 'wides' THEN batsman_runs ELSE total_runs END) AS total_runs
FROM IPL_Ball
WHERE NOT fielder= 'NA' GROUP BY fielder ORDER BY catches_stumpings DESC, total_runs DESC LIMIT 10;

/* To select a wicketkeeper for the T20 team */
--1. **Experience**: The wicketkeeper should have participated in multiple IPL seasons (More than 10) to bring experience to the team. 
--2. **Catches/Stumpings**: The wicketkeeper should have a significant number of catches and stumpings, indicating their agility and proficiency behind the stumps. in fielder column player name is written who took the catch
--3. **Runs Scored**: While wicketkeeping, the player should also contribute with the bat, so we can consider their total runs scored in the IPL matches.
--4. **Batting Strike Rate**: A good batting strike rate suggests the ability to score quick runs, which is crucial in T20 cricket.
--5. **Consistency**: Consistency in performance is important, so we can consider the average number of dismissals per Season in dismissal_kind column

--Based on these criteria, we can analyze the performance of wicketkeepers across IPL seasons and select the most suitable candidate for the wicketkeeper position in the team.

SELECT B.fielder AS wicketkeeper,
       COUNT(DISTINCT EXTRACT(year FROM m.date)) AS experience,
       COUNT(CASE WHEN B.dismissal_kind IN ('caught', 'stumped') THEN 1 END) AS catches_stumpings,
       SUM(CASE WHEN B.extras_type != 'wides' THEN B.batsman_runs ELSE B.total_runs END) AS total_runs,
       ROUND(SUM(CASE WHEN B.extras_type != 'wides' THEN B.batsman_runs ELSE B.total_runs END)* 100.0 
					/ NULLIF(COUNT(CASE WHEN B.extras_type != 'wides' THEN B.ball ELSE NULL END), 0), 2) 
	  				AS batting_strike_rate,
       COUNT(CASE WHEN B.dismissal_kind IN ('caught', 'stumped') THEN 1 END)*1.0 / COUNT(DISTINCT b.id) AS consistency
FROM IPL_Ball b
JOIN IPL_matches m ON b.id = m.id
WHERE NOT fielder= 'NA'
GROUP BY fielder HAVING COUNT(DISTINCT EXTRACT(year FROM m.date))>10 
ORDER BY catches_stumpings DESC, total_runs DESC, batting_strike_rate DESC
LIMIT 10;

SELECT batsman,
		SUM (total_runs)
		FROM ipl_ball
		where batsman= 'MS Dhoni' GROUP BY batsman;
		


-- Final Answer

SELECT FieldingStats.player AS "Wicketkeeper",
       FieldingStats.experience AS "Experience",
       FieldingStats.catches_stumpings AS "Total Catches/Stumpings",
       BattingStats.total_runs AS "Total Runs Scored",
       BattingStats.batting_strike_rate AS "Batting Strike Rate",
       ROUND(FieldingStats.catches_stumpings 
			 / NULLIF(FieldingStats.experience, 0), 2) AS "Consistency per Season"
FROM (
    SELECT B.fielder AS player,
           COUNT(DISTINCT EXTRACT(year FROM m.date)) AS experience,
           COUNT(CASE WHEN B.dismissal_kind IN ('caught', 'stumped') THEN 1 END) AS catches_stumpings
    FROM IPL_Ball b
    JOIN IPL_matches m ON b.id = m.id
    WHERE NOT fielder = 'NA'
    GROUP BY fielder
    HAVING COUNT(DISTINCT EXTRACT(year FROM m.date)) > 10) AS FieldingStats
LEFT JOIN (
    SELECT batsman AS player,
           SUM(CASE WHEN extras_type != 'wides' THEN batsman_runs ELSE total_runs END) AS total_runs,
           ROUND(SUM(CASE WHEN extras_type != 'wides' THEN batsman_runs ELSE total_runs END) * 100.0 
				 / NULLIF(COUNT(CASE WHEN extras_type != 'wides' 
								THEN ball ELSE NULL END), 0), 2) AS batting_strike_rate
    FROM IPL_Ball
    GROUP BY batsman
    HAVING COUNT(CASE WHEN extras_type != 'wides' THEN ball ELSE NULL END) > 500) AS BattingStats 
ON FieldingStats.player = BattingStats.player
ORDER BY "Total Catches/Stumpings" DESC, "Total Runs Scored" DESC, "Batting Strike Rate" DESC
LIMIT 10;




/* Additional Questions.1 */ 
SELECT COUNT ( DISTINCT city ) 
		AS "Count of cities that have hosted an IPL match" 
FROM IPL_matches;

/* Additional Questions.2 */
CREATE TABLE deliveries_v02 AS
SELECT *,
       CASE
           WHEN total_runs >= 4 THEN 'boundary'
           WHEN total_runs = 0 THEN 'dot'
           ELSE 'other'
       END AS ball_result
FROM IPL_Ball;

/* Additional Questions.3 */
SELECT  ball_result,
		COUNT (*) AS "No. of Total Deliveries",
		SUM (total_runs) AS "Total Runs"
FROM deliveries_v02
GROUP BY  ball_result;

/* Additional Questions.4 */

---- alternative1
SELECT  m.team1,
		SUM(CASE WHEN m.team1 = m.toss_winner AND m.toss_decision = 'bat' THEN dv.total_runs END) AS Case1_Totalrun,
		SUM(CASE WHEN m.team1 != m.toss_winner AND m.toss_decision = 'field' THEN dv.total_runs END) AS Case2_Totalrun,
		SUM(CASE WHEN m.team2 = m.toss_winner AND m.toss_decision = 'bat' THEN dv.total_runs END) AS Case3_Totalrun,
		SUM(CASE WHEN m.team2 != m.toss_winner AND m.toss_decision = 'field' THEN dv.total_runs END) AS Case4_Totalrun
		FROM ipl_matches AS m
		LEFT JOIN deliveries_v02 AS dv ON m.id = dv.id
		WHERE dv.inning = 1 AND dv.ball_result = 'boundary'
		GROUP BY m.team1;
		
SELECT COUNT (DISTINCT team1) FROM ipl_matches;
SELECT COUNT (DISTINCT team2) FROM ipl_matches;

SELECT  m.team2,
		SUM(CASE WHEN m.team1 != m.toss_winner AND m.toss_decision = 'bat' THEN dv.total_runs END) AS Case3_Totalrun,
		SUM(CASE WHEN m.team1 = m.toss_winner AND m.toss_decision = 'field' THEN dv.total_runs END) AS Case4_Totalrun
		FROM ipl_matches AS m
		LEFT JOIN deliveries_v02 AS dv ON m.id = dv.id
		WHERE dv.inning = 2 AND dv.ball_result = 'boundary'
		GROUP BY m.team1;

-- alternative2
SELECT m.team1,
       SUM(CASE 
               WHEN m.team1 = m.winner 
               THEN (dv.total_B_Run + m.result_margin) / 2 
               ELSE (dv.total_B_Run - m.result_margin) / 2 
           END) AS Case1_Totalrun,
	    SUM(CASE 
               WHEN m.team2 = m.winner 
               THEN (dv.total_B_Run + m.result_margin) / 2 
               ELSE (dv.total_B_Run - m.result_margin) / 2 
           END) AS Case2_Totalrun
FROM ipl_matches AS m
LEFT JOIN (
    SELECT id, 
           SUM(total_runs) AS total_B_Run
    FROM deliveries_v02 
    WHERE ball_result = 'boundary' GROUP BY id) AS dv ON m.id = dv.id
GROUP BY m.team1;

-- alternative3
SELECT team,
       SUM(CASE 
               WHEN team = winner 
               THEN (total_B_Run + result_margin) / 2 
               ELSE (total_B_Run - result_margin) / 2 
           END) AS Totalrun
FROM ( SELECT team1 AS team, id, winner, result_margin
       FROM ipl_matches
    
       UNION ALL
    
       SELECT team2 AS team, id, winner, result_margin
       FROM ipl_matches) AS m
LEFT JOIN (SELECT id, 
           SUM(total_runs) AS total_B_Run
           FROM deliveries_v02 
           WHERE ball_result = 'boundary' 
           GROUP BY id) AS dv ON m.id = dv.id
GROUP BY team;

--Final Answer
SELECT batting_team,
       COUNT(CASE WHEN ball_result = 'boundary' THEN 1 END) AS "No of total_boundaries"
FROM deliveries_v02
GROUP BY batting_team
ORDER BY "No of total_boundaries" DESC;


/* Additional Questions.5 */

--finding and updating the bowling team 
SELECT batting_team, bowling_team, MAX(DISTINCT id) AS id
FROM deliveries_v02 
WHERE bowling_team = 'NA'
GROUP BY bowling_team, batting_team;

--finding missing bowling_team from IPL_Matches through ID
SELECT id, team1, team2 FROM ipl_matches WHERE id IN (501265, 829763);

--for match id 501265 Bowling_team updated 'NA' to 'Pune Warriors'(Data collected from IPL_Matches)
UPDATE deliveries_v02 SET bowling_team = 'Pune Warriors' WHERE id = 501265;

--for match id 829763 Bowling_team updated 'NA' to 'Rajasthan Royals'(Data collected from IPL_Matches)
UPDATE deliveries_v02 SET bowling_team = 'Rajasthan Royals' WHERE id = 829763;

--from previous data the value of total dot_ball  --'Pune Warriors' =1900,'Rajasthan Royals' =6665, 'NA' = 71
--final query where removed the 'NA'
SELECT bowling_team,
       COUNT(CASE WHEN ball_result = 'dot' THEN 1 END) AS total_dotballs
FROM deliveries_v02
GROUP BY bowling_team
ORDER BY total_dotballs DESC;  

/* Additional Questions.6 */
SELECT dismissal_kind, COUNT(*) AS total_dismissals
FROM IPL_Ball
WHERE dismissal_kind != 'NA'
GROUP BY dismissal_kind
ORDER BY total_dismissals DESC;

/* Additional Questions.7 */
SELECT bowler,
		SUM(extra_runs) AS "Conceded extra_runs"
	FROM IPL_Ball
	GROUP BY bowler
	ORDER BY SUM(extra_runs) DESC
	LIMIT 5;

/* Additional Questions.8 */
CREATE TABLE deliveries_v03 AS
SELECT deliveries.*,
		match.venue AS "Venue of the Match",
		match.date AS "Date of the Match"
	FROM deliveries_v02 AS deliveries
	LEFT JOIN ipl_matches AS match 
	ON deliveries.id = match.id;

/* Additional Questions.9 */
SELECT m.venue AS "Venue of the Match",
       SUM(b.total_runs) AS total_runs
FROM IPL_Ball b
JOIN IPL_matches m ON b.id = m.id
GROUP BY m.venue
ORDER BY total_runs DESC;

/* Additional Questions.10 */
SELECT EXTRACT(year FROM m.date) AS year,
       SUM(b.total_runs) AS total_runs
FROM IPL_Ball b
JOIN IPL_matches m ON b.id = m.id
WHERE m.venue = 'Eden Gardens'
GROUP BY year
ORDER BY total_runs DESC;


SELECT  batsman AS "Aggressive batsmen",
        total_runs,
        balls_faced,
        ROUND(total_runs * 100.0 
			  / NULLIF(balls_faced, 0), 2) AS strike_rate
FROM ( SELECT 
        batsman,
        SUM(Total_runs) AS total_runs,
        COUNT(CASE WHEN extras_type != 'wides' 
			  THEN ball ELSE NULL END) AS balls_faced
       FROM IPL_Ball
       GROUP BY batsman)
	   WHERE ROUND(total_runs * 100.0 
			  / NULLIF(balls_faced, 0), 2)>100
ORDER BY total_runs DESC
LIMIT 10;

ALTER TABLE ipl_ball ADD address varchar();