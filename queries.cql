// where do the fouls happen
match (match:Match {id: "32683310"})<-[:COMMITTED_IN_MATCH]-(foul)
RETURN foul.location AS location, COUNT(*) as fouls
ORDER BY fouls DESC;

// who fouls the most
match (match:Match {id: "32683310"})<-[:COMMITTED_IN_MATCH]-(foul)<-[:COMMITTED_FOUL]-(fouler)
RETURN fouler.name AS fouler, COUNT(*) as fouls
ORDER BY fouls DESC
LIMIT 10;

// who was fouled the most
match (match:Match {id: "32683310"})<-[:COMMITTED_IN_MATCH]-(foul)-[:COMMITTED_AGAINST]->(fouled)
RETURN fouled.name AS fouled, COUNT(*) as fouls
ORDER BY fouls DESC
LIMIT 10;

// who fouled who the most
match (match:Match {id: "32683310"})<-[:COMMITTED_IN_MATCH]-(foul)-[:COMMITTED_AGAINST]->(fouled),
      (foul)<-[:COMMITTED_FOUL]-(fouler)
RETURN fouler.name AS fouler, fouled.name AS fouled, COUNT(*) as fouls
ORDER BY fouls DESC
LIMIT 10;

// which team fouled most
match (match:Match {id: "32683310"})<-[:COMMITTED_IN_MATCH]-(foul)<-[:COMMITTED_FOUL]-(fouler),
      (fouler)-[:MADE_APPEARANCE]-(app)-[:IN_MATCH]-(match),
      (app)-[:FOR_TEAM]->(team)
RETURN team.name, COUNT(*) as fouls
ORDER BY fouls DESC
LIMIT 10;

// worst fouler for each team?
match (match:Match {id: "32683310"})<-[:COMMITTED_IN_MATCH]-(foul)<-[:COMMITTED_FOUL]-(fouler),
      (fouler)-[:MADE_APPEARANCE]-(app)-[:IN_MATCH]-(match),
      (app)-[:FOR_TEAM]->(team)
WITH team, fouler, COUNT(*) AS fouls
ORDER BY team.name, fouls DESC
WITH team, COLLECT({fouler:fouler, fouls:fouls})[0] AS topFouler
RETURN team.name, topFouler.fouler.name, topFouler.fouls;

// most fouled against for each team
match (match:Match {id: "32683310"})<-[:COMMITTED_IN_MATCH]-(foul)-[:COMMITTED_AGAINST]-(fouled),
      (fouled)-[:MADE_APPEARANCE]-(app)-[:IN_MATCH]-(match),
      (app)-[:FOR_TEAM]->(team)
WITH team, fouled, COUNT(*) AS fouls
ORDER BY team.name, fouls DESC
WITH team, COLLECT({fouled:fouled, fouls:fouls})[0] AS topFouled
RETURN team.name, topFouled.fouled.name, topFouled.fouls;


//  what did neymar do in the match?
match (p:Player {name: "Neymar"})-[:MADE_APPEARANCE]->(app)-[r]-(event:Event)
RETURN event, [label in LABELS(event) where label <> "Event"][0] AS type
ORDER BY event.time

// find the corners conceded by each goalkeeper

// find the goal scorers for both teams in the match

// fouls that led to cards and those that didn't
match (foul:Foul)<-[:COMMITTED_FOUL]-(app),
      (player)-[:MADE_APPEARANCE]->(app),
      (foul)-[:COMMITTED_AGAINST]->()<-[:MADE_APPEARANCE]-(otherPlayer)
optional match (foul)-[:RESULTED_IN]->(card)-[:GIVEN_TO]->(app)
RETURN player.name, foul.time, foul.location, card.type, otherPlayer.name
ORDER BY foul.time

// chances created, goals scored


// who's providing the assists for goals
