// Players index
CREATE CONSTRAINT ON (player:Player)
ASSERT player.id IS UNIQUE;

// match
LOAD CSV WITH HEADERS FROM "file:///Users/markhneedham/projects/neo4j-bbc/data/events.csv" AS row
MERGE (match:Match {id: row.matchId});

// teams
LOAD CSV WITH HEADERS FROM "file:///Users/markhneedham/projects/neo4j-bbc/data/events.csv" AS row
MERGE (:Team {name: row.foulingPlayerTeam});

LOAD CSV WITH HEADERS FROM "file:///Users/markhneedham/projects/neo4j-bbc/data/events.csv" AS row
MERGE (:Team {name: row.fouledPlayerTeam});

// players
LOAD CSV WITH HEADERS FROM "file:///Users/markhneedham/projects/neo4j-bbc/data/events.csv" AS row
MERGE (player:Player {id: row.foulingPlayer + "_" + row.foulingPlayerTeam})
ON CREATE SET player.name = row.foulingPlayer;

LOAD CSV WITH HEADERS FROM "file:///Users/markhneedham/projects/neo4j-bbc/data/events.csv" AS row
MERGE (player:Player {id: row.fouledPlayer + "_" + row.fouledPlayerTeam})
ON CREATE SET player.name = row.fouledPlayer;

// appearance
LOAD CSV WITH HEADERS FROM "file:///Users/markhneedham/projects/neo4j-bbc/data/events.csv" AS row
MATCH (match:Match {id: row.matchId})
MATCH (player:Player {id: row.foulingPlayer + "_" + row.foulingPlayerTeam})
MATCH (team:Team {name: row.foulingPlayerTeam})

MERGE (appearance:Appearance {id: player.id + " in " + row.matchId})
MERGE (player)-[:MADE_APPEARANCE]-(appearance)
MERGE (appearance)-[:IN_MATCH]-(match)
MERGE (appearance)-[:FOR_TEAM]-(team);

LOAD CSV WITH HEADERS FROM "file:///Users/markhneedham/projects/neo4j-bbc/data/events.csv" AS row
MATCH (match:Match {id: row.matchId})
MATCH (player:Player {id: row.fouledPlayer + "_" + row.fouledPlayerTeam})
MATCH (team:Team {name: row.fouledPlayerTeam})

MERGE (appearance:Appearance {id: player.id + " in " + row.matchId})
MERGE (player)-[:MADE_APPEARANCE]-(appearance)
MERGE (appearance)-[:IN_MATCH]-(match)
MERGE (appearance)-[:FOR_TEAM]-(team);

// fouls

LOAD CSV WITH HEADERS FROM "file:///Users/markhneedham/projects/neo4j-bbc/data/events.csv" AS row

MATCH (foulingPlayer:Player {id:row.foulingPlayer + "_" + row.foulingPlayerTeam })
MATCH (fouledPlayer:Player {id:row.fouledPlayer + "_" + row.fouledPlayerTeam })
MATCH (match:Match {id: row.matchId})

MERGE (foul:Foul {eventId: row.foulId})
ON CREATE SET foul.time = row.time, foul.location = row.foulLocation

MERGE (foul)<-[:COMMITTED_FOUL]-(foulingPlayer)
MERGE (foul)-[:COMMITTED_AGAINST]-(fouledPlayer)
MERGE (foul)-[:COMMITTED_IN_MATCH]-(match);
