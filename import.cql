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

// match
LOAD CSV WITH HEADERS FROM "file:///Users/markneedham/projects/neo4j-bbc/data/fouls.csv" AS row
MERGE (:Match {id: row.matchId});

// teams
LOAD CSV WITH HEADERS FROM "file:///Users/markneedham/projects/neo4j-bbc/data/fouls.csv" AS row
MERGE (:Team {name: row.foulingPlayerTeam});

LOAD CSV WITH HEADERS FROM "file:///Users/markneedham/projects/neo4j-bbc/data/fouls.csv" AS row
MERGE (:Team {name: row.fouledPlayerTeam});

// players
LOAD CSV WITH HEADERS FROM "file:///Users/markneedham/projects/neo4j-bbc/data/players.csv" AS row
MERGE (player:Player {id: row.player + "_" + row.team})
ON CREATE SET player.name = row.player;

// appearances
LOAD CSV WITH HEADERS FROM "file:///Users/markneedham/projects/neo4j-bbc/data/players.csv" AS row
MATCH (match:Match {id: row.matchId})
MATCH (player:Player {id: row.player + "_" + row.team})
MATCH (team:Team {name: row.team})
MERGE (appearance:Appearance {id: player.id + " in " + row.matchId})
MERGE (player)-[:MADE_APPEARANCE]->(appearance)
MERGE (appearance)-[:IN_MATCH]->(match)
MERGE (appearance)-[:FOR_TEAM]->(team);

// fouls
LOAD CSV WITH HEADERS FROM "file:///Users/markneedham/projects/neo4j-bbc/data/fouls.csv" AS row

MATCH (foulingPlayer:Player {id:row.foulingPlayer + "_" + row.foulingPlayerTeam })
MATCH (fouledPlayer:Player {id:row.fouledPlayer + "_" + row.fouledPlayerTeam })
MATCH (match:Match {id: row.matchId})

MERGE (foul:Foul:Event {eventId: row.matchId + "_" + row.foulId})
ON CREATE SET foul.time = row.time, foul.sortableTime = toint(row.sortableTime), foul.location = row.foulLocation

MERGE (foul)<-[:COMMITTED_FOUL]-(foulingPlayer)
MERGE (foul)-[:COMMITTED_AGAINST]->(fouledPlayer)
MERGE (foul)-[:COMMITTED_IN_MATCH]->(match);

// refactor the fouls to hook to appearances
match (foul:Foul)-[:COMMITTED_AGAINST]->(fouledPlayer),
      (foul)<-[:COMMITTED_FOUL]-(foulingPlayer),
      (foul)-[:COMMITTED_IN_MATCH]->(match:Match {id: "32683310"}),
      (foulingPlayer)-[:MADE_APPEARANCE]-(foulingPlayerApp)-[:IN_MATCH]->(match),
      (fouledPlayer)-[:MADE_APPEARANCE]-(fouledPlayerApp)-[:IN_MATCH]->(match)
MERGE (foul)<-[:COMMITTED_FOUL]-(foulingPlayerApp)
MERGE (foul)-[:COMMITTED_AGAINST]->(fouledPlayerApp);

// remove the old rels
match (match:Match {id: "32683310"})<-[oldRel:COMMITTED_IN_MATCH]-(foul:Foul)
DELETE oldRel;

match (player:Player)<-[oldRel:COMMITTED_AGAINST]-(foul:Foul)
DELETE oldRel;

match (player:Player)-[oldRel:COMMITTED_FOUL]->(foul:Foul)
DELETE oldRel;

// attempts
LOAD CSV WITH HEADERS FROM "file:///Users/markneedham/projects/neo4j-bbc/data/attempts.csv" AS row

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
LOAD CSV WITH HEADERS FROM "file:///Users/markneedham/projects/neo4j-bbc/data/attempts.csv" AS row

MATCH (assistingPlayer:Player {id:row.assistedBy + "_" + row.attemptByTeam })
MATCH (attempt:Attempt:Event {attemptId: row.matchId + "_" + row.attemptId})
MATCH (match:Match {id: row.matchId})
MATCH (assistingPlayer)-[:MADE_APPEARANCE]->(app)-[:IN_MATCH]-(match)

MERGE (attempt)<-[:PROVIDED_ASSIST_FOR]-(app);

// corners from an attempt
LOAD CSV WITH HEADERS FROM "file:///Users/markneedham/projects/neo4j-bbc/data/corners.csv" AS row

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
LOAD CSV WITH HEADERS FROM "file:///Users/markneedham/projects/neo4j-bbc/data/corners.csv" AS row

WITH row WHERE row.attemptId is null
MERGE (match:Match {id: row.matchId})

WITH row, match
MATCH (concededBy:Player {name: row.concededBy})

WITH match, concededBy, row
MATCH (concededBy)-[:MADE_APPEARANCE]->(concededByApp)-[:IN_MATCH]-(match)
MERGE (corner:Corner {cornerId: row.cornerId})

MERGE (corner)-[:CONCEDED_BY]->(concededByApp);

// bookings with fouls
LOAD CSV WITH HEADERS FROM "file:///Users/markneedham/projects/neo4j-bbc/data/cards.csv" AS row
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
LOAD CSV WITH HEADERS FROM "file:///Users/markneedham/projects/neo4j-bbc/data/cards.csv" AS row
WITH row WHERE row.foulId is null

MERGE (card:Card:Event:Yellow {eventId: row.matchId + "_" + row.cardId})
SET card.type = "yellow", card.time = row.time, card.sortableTime = toint(row.sortableTime)
WITH card, row

MATCH (match:Match {id: row.matchId})
MATCH (player:Player {id: row.player + "_" + row.playerTeam})
MATCH (player)-[:MADE_APPEARANCE]->(app)-[:IN_MATCH]-(match)

MERGE (card)-[:GIVEN_TO]->(app);

// foul revenge
match (foul:Foul)
WITH foul
ORDER BY foul.sortableTime
WITH COLLECT(foul) AS fouls
FOREACH(i in range(0, length(fouls) -2) |
  FOREACH(foul1 in [fouls[i]] | FOREACH (foul2 in [fouls[i+1]] |
    MERGE (foul1)-[:NEXT]->(foul2)
)));

// subs

LOAD CSV WITH HEADERS FROM "file:///Users/markneedham/projects/neo4j-bbc/data/subs.csv" AS row

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
