// Players index
CREATE CONSTRAINT ON (player:Player)
ASSERT player.id IS UNIQUE;

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

MERGE (foul:Foul:Event {eventId: row.foulId})
ON CREATE SET foul.time = row.time, foul.location = row.foulLocation

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

MERGE (attempt:Attempt:Event {attemptId: row.attemptId})
ON CREATE SET attempt.time = row.time, attempt.outcome = row.attemptOutcome

MERGE (match:Match {id: row.matchId})

MERGE (appearance)-[:HAD_ATTEMPT]->(attempt);

// corners
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
