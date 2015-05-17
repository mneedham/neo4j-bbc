// Players index
CREATE CONSTRAINT ON (player:Player)
ASSERT player.id IS UNIQUE;

// match
LOAD CSV WITH HEADERS FROM "file:///Users/markhneedham/projects/neo4j-bbc/data/fouls.csv" AS row
MERGE (:Match {id: row.matchId});

// teams
LOAD CSV WITH HEADERS FROM "file:///Users/markhneedham/projects/neo4j-bbc/data/fouls.csv" AS row
MERGE (:Team {name: row.foulingPlayerTeam});

LOAD CSV WITH HEADERS FROM "file:///Users/markhneedham/projects/neo4j-bbc/data/fouls.csv" AS row
MERGE (:Team {name: row.fouledPlayerTeam});

// players
LOAD CSV WITH HEADERS FROM "file:///Users/markhneedham/projects/neo4j-bbc/data/fouls.csv" AS row
MERGE (player1:Player {id: row.foulingPlayer + "_" + row.foulingPlayerTeam})
ON CREATE SET player1.name = row.foulingPlayer

MERGE (player2:Player {id: row.fouledPlayer + "_" + row.fouledPlayerTeam})
ON CREATE SET player2.name = row.fouledPlayer;

LOAD CSV WITH HEADERS FROM "file:///Users/markhneedham/projects/neo4j-bbc/data/attempts.csv" AS row
MERGE (player1:Player {id: row.attemptBy + "_" + row.attemptByTeam})
ON CREATE SET player1.name = row.attemptBy;

// appearances
LOAD CSV WITH HEADERS FROM "file:///Users/markhneedham/projects/neo4j-bbc/data/fouls.csv" AS row
MATCH (match:Match {id: row.matchId})
MATCH (player:Player {id: row.foulingPlayer + "_" + row.foulingPlayerTeam})
MATCH (team:Team {name: row.foulingPlayerTeam})

MERGE (appearance:Appearance {id: player.id + " in " + row.matchId})
MERGE (player)-[:MADE_APPEARANCE]->(appearance)
MERGE (appearance)-[:IN_MATCH]->(match)
MERGE (appearance)-[:FOR_TEAM]->(team);

LOAD CSV WITH HEADERS FROM "file:///Users/markhneedham/projects/neo4j-bbc/data/fouls.csv" AS row
MATCH (match:Match {id: row.matchId})
MATCH (player:Player {id: row.fouledPlayer + "_" + row.fouledPlayerTeam})
MATCH (team:Team {name: row.fouledPlayerTeam})

MERGE (appearance:Appearance {id: player.id + " in " + row.matchId})
MERGE (player)-[:MADE_APPEARANCE]->(appearance)
MERGE (appearance)-[:IN_MATCH]->(match)
MERGE (appearance)-[:FOR_TEAM]->(team);

// fouls
LOAD CSV WITH HEADERS FROM "file:///Users/markhneedham/projects/neo4j-bbc/data/fouls.csv" AS row

MATCH (foulingPlayer:Player {id:row.foulingPlayer + "_" + row.foulingPlayerTeam })
MATCH (fouledPlayer:Player {id:row.fouledPlayer + "_" + row.fouledPlayerTeam })
MATCH (match:Match {id: row.matchId})

MERGE (foul:Foul {eventId: row.foulId})
ON CREATE SET foul.time = row.time, foul.location = row.foulLocation

MERGE (foul)<-[:COMMITTED_FOUL]-(foulingPlayer)
MERGE (foul)-[:COMMITTED_AGAINST]->(fouledPlayer)
MERGE (foul)-[:COMMITTED_IN_MATCH]->(match);

// attempts
LOAD CSV WITH HEADERS FROM "file:///Users/markhneedham/projects/neo4j-bbc/data/attempts.csv" AS row

MERGE (attemptingPlayer:Player {id:row.attemptBy + "_" + row.attemptByTeam })
ON CREATE SET attemptingPlayer.name = row.attemptBy

MERGE (attempt:Attempt {attemptId: row.attemptId})
ON CREATE SET attempt.time = row.time, attempt.outcome = row.attemptOutcome

MERGE (match:Match {id: row.matchId})

MERGE (attemptingPlayer)-[:HAD_ATTEMPT]->(attempt)
MERGE (attempt)-[:IN_MATCH]->(match);
