// Indexes
CREATE CONSTRAINT ON (player:Player)
ASSERT player.id IS UNIQUE;

CREATE CONSTRAINT ON (match:Match)
ASSERT match.id IS UNIQUE;

CREATE CONSTRAINT ON (team:Team)
ASSERT team.name IS UNIQUE;

CREATE CONSTRAINT ON (player:Player)
ASSERT player.id IS UNIQUE;

CREATE CONSTRAINT ON (app:Appearance)
ASSERT app.id IS UNIQUE;

// matches
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/mneedham/neo4j-bbc/master/data/matches.csv" AS row
MERGE (m:Match {id: row.matchId})
SET m.home = row.home, m.away = row.away, m.homeScore = toint(row.homeScore), m.awayScore = toint(row.awayScore)

WITH *
MERGE (home:Team {name: row.home})
MERGE (away:Team {name: row.away})
MERGE (m)-[:HOME_TEAM]->(home)
MERGE (m)-[:AWAY_TEAM]->(away);

// players
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/mneedham/neo4j-bbc/master/data/players.csv" AS row
MERGE (player:Player {id: row.player + "_" + row.team})
ON CREATE SET player.name = row.player;

// appearances
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/mneedham/neo4j-bbc/master/data/players.csv" AS row
MATCH (match:Match {id: row.matchId})
MATCH (player:Player {id: row.player + "_" + row.team})
MATCH (team:Team {name: row.team})
MERGE (appearance:Appearance {id: player.id + " in " + row.matchId})
MERGE (player)-[:MADE_APPEARANCE]->(appearance)
MERGE (appearance)-[:IN_MATCH]->(match)
MERGE (appearance)-[:FOR_TEAM]->(team);

// fouls
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/mneedham/neo4j-bbc/master/data/fouls.csv" AS row

MATCH (foulingPlayer:Player {id:row.foulingPlayer + "_" + row.foulingPlayerTeam })
MATCH (fouledPlayer:Player {id:row.fouledPlayer + "_" + row.fouledPlayerTeam })
MATCH (match:Match {id: row.matchId})

MATCH (foulingPlayer)-[:MADE_APPEARANCE]->(foulingPlayerApp)-[:IN_MATCH]-(match)
MATCH (fouledPlayer)-[:MADE_APPEARANCE]->(fouledPlayerApp)-[:IN_MATCH]-(match)

MERGE (foul:Foul:Event {eventId: row.matchId + "_" + row.foulId})
ON CREATE SET foul.time = row.time, foul.sortableTime = toint(row.sortableTime), foul.location = row.foulLocation

MERGE (foul)<-[:COMMITTED_FOUL]-(foulingPlayerApp)
MERGE (foul)-[:COMMITTED_AGAINST]->(fouledPlayerApp)
MERGE (foul)-[:COMMITTED_IN_MATCH]->(match);

// attempts
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/mneedham/neo4j-bbc/master/data/attempts.csv" AS row

MERGE (attemptingPlayer:Player {id:row.attemptBy + "_" + row.attemptByTeam })
ON CREATE SET attemptingPlayer.name = row.attemptBy

MERGE (appearance:Appearance {id: attemptingPlayer.id + " in " + row.matchId})

MERGE (attempt:Attempt:Event {attemptId: row.matchId + "_" + row.attemptId})
ON CREATE SET attempt.time = row.time, attempt.sortableTime = toint(row.sortableTime), attempt.outcome = row.attemptOutcome

FOREACH(ignoreMe IN CASE WHEN attempt.outcome = "goal" THEN [1] ELSE [] END |
  SET attempt:Goal)

MERGE (match:Match {id: row.matchId})
MERGE (appearance)-[:HAD_ATTEMPT]->(attempt);

// assists for attempts
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/mneedham/neo4j-bbc/master/data/attempts.csv" AS row

MATCH (assistingPlayer:Player {id:row.assistedBy + "_" + row.attemptByTeam })
MATCH (attempt:Attempt:Event {attemptId: row.matchId + "_" + row.attemptId})
MATCH (match:Match {id: row.matchId})
MATCH (assistingPlayer)-[:MADE_APPEARANCE]->(app)-[:IN_MATCH]-(match)

MERGE (attempt)<-[:PROVIDED_ASSIST_FOR]-(app);

// corners from an attempt
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/mneedham/neo4j-bbc/master/data/corners.csv" AS row

WITH row WHERE row.attemptId <> ""
MERGE (match:Match {id: row.matchId})

WITH row, match
MATCH (concededBy:Player {name: row.concededBy})

WITH match, concededBy, row
MATCH (concededBy)-[:MADE_APPEARANCE]->(concededByApp)-[:IN_MATCH]-(match)
MATCH (attempt:Attempt {attemptId: row.attemptId})
MERGE (corner:Corner {cornerId: row.cornerId})

MERGE (attempt)-[:LED_TO]->(corner)
MERGE (corner)-[:CONCEDED_BY]->(concededByApp);

// corners not from an attempt
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/mneedham/neo4j-bbc/master/data/corners.csv" AS row

WITH row WHERE row.attemptId is null
MERGE (match:Match {id: row.matchId})

WITH row, match
MATCH (concededBy:Player {name: row.concededBy})

WITH match, concededBy, row
MATCH (concededBy)-[:MADE_APPEARANCE]->(concededByApp)-[:IN_MATCH]-(match)
MERGE (corner:Corner {cornerId: row.cornerId})

MERGE (corner)-[:CONCEDED_BY]->(concededByApp);

// bookings with fouls
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/mneedham/neo4j-bbc/master/data/cards.csv" AS row
WITH row WHERE row.foulId <> ""

MERGE (card:Card:Event:Yellow {eventId: row.matchId + "_" + row.cardId})
SET card.type = "yellow", card.time = row.time, card.sortableTime = toint(row.sortableTime)
WITH card, row

MATCH (match:Match {id: row.matchId})
MATCH (player:Player {id: row.player + "_" + row.playerTeam})
MATCH (foul:Foul:Event {eventId: row.matchId + "_" + row.foulId})
MATCH (player)-[:MADE_APPEARANCE]->(app)-[:IN_MATCH]-(match)

MERGE (foul)-[:RESULTED_IN]->(card)
MERGE (card)-[:GIVEN_TO]->(app);

// bookings with no fouls
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/mneedham/neo4j-bbc/master/data/cards.csv" AS row
WITH row WHERE row.foulId is null

MERGE (card:Card:Event:Yellow {eventId: row.matchId + "_" + row.cardId})
SET card.type = "yellow", card.time = row.time, card.sortableTime = toint(row.sortableTime)
WITH card, row

MATCH (match:Match {id: row.matchId})
MATCH (player:Player {id: row.player + "_" + row.playerTeam})
MATCH (player)-[:MADE_APPEARANCE]->(app)-[:IN_MATCH]-(match)

MERGE (card)-[:GIVEN_TO]->(app);

// foul revenge
MATCH (foul:Foul)-[:COMMITTED_IN_MATCH]->(match)
WITH foul,match
ORDER BY match.id, foul.sortableTime
WITH match, COLLECT(foul) AS fouls
FOREACH(i in range(0, length(fouls) -2) |
  FOREACH(foul1 in [fouls[i]] | FOREACH (foul2 in [fouls[i+1]] |
    MERGE (foul1)-[:NEXT]->(foul2)
)));

// subs

LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/mneedham/neo4j-bbc/master/data/subs.csv" AS row

MERGE (sub:Sub:Event {subId: row.matchId + "_" + row.subId})
SET sub.time = row.time, sub.sortableTime = toint(row.sortableTime)
WITH sub, row

MATCH (match:Match {id: row.matchId})
MATCH (playerOn:Player {id: row.on + "_" + row.team})
MATCH (playerOff:Player {id: row.off + "_" + row.team})

MATCH (playerOn)-[:MADE_APPEARANCE]->(onApp)-[:IN_MATCH]-(match)
MATCH (playerOff)-[:MADE_APPEARANCE]->(offApp)-[:IN_MATCH]-(match)

MERGE (sub)-[:ON]->(onApp)
MERGE (sub)-[:OFF]->(offApp);
