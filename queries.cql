// where do the fouls happen
match (match:Match)<-[:COMMITTED_IN_MATCH]-(foul)
RETURN foul.location AS location, COUNT(*) as fouls
ORDER BY fouls DESC;

// who fouls the most
match (match:Match)<-[:COMMITTED_IN_MATCH]-(foul)<-[:COMMITTED_FOUL]-(fouler)
RETURN fouler.name AS fouler, COUNT(*) as fouls
ORDER BY fouls DESC;

// who was fouled the most
match (match:Match)<-[:COMMITTED_IN_MATCH]-(foul)-[:COMMITTED_AGAINST]->(fouled)
RETURN fouled.name AS fouled, COUNT(*) as fouls
ORDER BY fouls DESC;


// who fouled who the most
match (match:Match)<-[:COMMITTED_IN_MATCH]-(foul)-[:COMMITTED_AGAINST]->(fouled),
      (foul)<-[:COMMITTED_FOUL]-(fouler)
RETURN fouler.name AS fouler, fouled.name AS fouled, COUNT(*) as fouls
ORDER BY fouls DESC;

// which team fouled most
match (match:Match)<-[:COMMITTED_IN_MATCH]-(foul)<-[:COMMITTED_FOUL]-(fouler),
      (fouler)-[:MADE_APPEARANCE]-(app)-[:IN_MATCH]-(match),
      (app)-[:FOR_TEAM]->(team)
RETURN team.name, COUNT(*) as fouls
ORDER BY fouls DESC;

// worst fouler for each team?
match (match:Match)<-[:COMMITTED_IN_MATCH]-(foul)<-[:COMMITTED_FOUL]-(fouler),
      (fouler)-[:MADE_APPEARANCE]-(app)-[:IN_MATCH]-(match),
      (app)-[:FOR_TEAM]->(team)
WITH team, fouler, COUNT(*) AS fouls
ORDER BY team.name, fouls DESC
WITH team, COLLECT({fouler:fouler, fouls:fouls})[0] AS topFouler
RETURN team.name, topFouler.fouler.name, topFouler.fouls;

// most fouled against for each team

match (match:Match)<-[:COMMITTED_IN_MATCH]-(foul)-[:COMMITTED_AGAINST]-(fouled),
      (fouled)-[:MADE_APPEARANCE]-(app)-[:IN_MATCH]-(match),
      (app)-[:FOR_TEAM]->(team)
WITH team, fouled, COUNT(*) AS fouls
ORDER BY team.name, fouls DESC
WITH team, COLLECT({fouled:fouled, fouls:fouls})[0] AS topFouled
RETURN team.name, topFouled.fouled.name, topFouled.fouls;
