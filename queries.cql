// where do the fouls happen
match (match:Match {id: "32683310"})<-[:IN_MATCH]-()<-[]-(foul:Foul)
RETURN foul.location AS location, COUNT(*) as fouls
ORDER BY fouls DESC

// who fouls the most
match (match:Match {id: "32683310"})<-[:IN_MATCH]-(appearance)-[:COMMITTED_FOUL]->(foul:Foul),
      (appearance)<-[:MADE_APPEARANCE]-(fouler)
RETURN fouler.name AS fouler, COUNT(*) as fouls
ORDER BY fouls DESC
LIMIT 10

// who was fouled the most
match (match:Match {id: "32683310"})<-[:IN_MATCH]-(appearance)<-[:COMMITTED_AGAINST]->(foul:Foul),
      (appearance)<-[:MADE_APPEARANCE]-(fouled)
RETURN fouled.name AS fouled, COUNT(*) as fouls
ORDER BY fouls DESC
LIMIT 10

// who fouled who the most
match (match:Match {id: "32683310"}),
      (match)<-[:IN_MATCH]-(fouledApp)<-[:COMMITTED_AGAINST]->(foul:Foul)<-[:COMMITTED_FOUL]-(foulerApp)-[:IN_MATCH]->(match),
      (fouledApp)<-[:MADE_APPEARANCE]-(fouled),
      (foulerApp)<-[:MADE_APPEARANCE]-(fouler)
RETURN fouler.name AS fouler, fouled.name AS fouled, COUNT(*) as fouls
ORDER BY fouls DESC
LIMIT 10;

// which team fouled most
match (match:Match {id: "32683310"})<-[:COMMITTED_IN_MATCH]-()<-[:COMMITTED_FOUL]-(fouler),
      (fouler)-[:MADE_APPEARANCE]-(app)-[:IN_MATCH]-(match),
      (app)-[:FOR_TEAM]->(team)
RETURN team.name, COUNT(*) as fouls
ORDER BY fouls DESC

// worst fouler for each team?
match (match:Match {id: "32683310"})<-[:IN_MATCH]-(app:Appearance)-[:COMMITTED_FOUL]->(),
      (app)-[:FOR_TEAM]->(team),
      (fouler)-[:MADE_APPEARANCE]->(app)
WITH team, fouler, COUNT(*) AS fouls
ORDER BY team.name, fouls DESC
WITH team, COLLECT({fouler:fouler, fouls:fouls})[0] AS topFouler
RETURN team.name, topFouler.fouler.name, topFouler.fouls;

// most fouled against for each team
match (match:Match {id: "32683310"})<-[:IN_MATCH]-(app:Appearance)<-[:COMMITTED_AGAINST]->(),
      (app)-[:FOR_TEAM]->(team),
      (fouled)-[:MADE_APPEARANCE]->(app)
WITH team, fouled, COUNT(*) AS fouls
ORDER BY team.name, fouls DESC
WITH team, COLLECT({fouled:fouled, fouls:fouls})[0] AS topFouled
RETURN team.name, topFouled.fouled.name, topFouled.fouls

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
match (app:Appearance)-[:PROVIDED_ASSIST_FOR]->(attempt),
      (player)-[:MADE_APPEARANCE]->(app),
      (attempt)<-[:HAD_ATTEMPT]-()<-[:MADE_APPEARANCE]-(otherPlayer)
RETURN attempt.time, player.name, attempt.outcome, otherPlayer.name
ORDER BY attempt.sortableTime

// top assister
match (app:Appearance)-[:PROVIDED_ASSIST_FOR]->(attempt),
      (player)-[:MADE_APPEARANCE]->(app),
      (attempt)<-[:HAD_ATTEMPT]-()<-[:MADE_APPEARANCE]-(otherPlayer)
WITH player, COUNT(*) AS assists, COLLECT(attempt) AS attempts
RETURN player.name,
       LENGTH([attempt in attempts WHERE attempt:Goal]) AS goalAssists,
       LENGTH([attempt in attempts WHERE NOT attempt:Goal]) AS nonGoalAssists,
       assists
ORDER BY assists DESC

// revenge foulers
match (foul1:Foul)-[:COMMITTED_AGAINST]->(app1)-[:COMMITTED_FOUL]->(foul2)-[:COMMITTED_AGAINST]->(app2)-[:COMMITTED_FOUL]->(foul1),
      (player1)-[:MADE_APPEARANCE]->(app1), (player2)-[:MADE_APPEARANCE]->(app2),
      (foul1)-[:COMMITTED_IN_MATCH]->(match:Match {id: "32683310"})<-[:COMMITTED_IN_MATCH]-(foul2)
WHERE (foul1)-[:NEXT*]->(foul2)
RETURN player2.name AS firstFouler, player1.name AS revengeFouler, foul1.time, foul1.location, foul2.time, foul2.location

// on the edge - fouling after getting a yellow

// substitutes
match (player:Player)-[:MADE_APPEARANCE]->(app)-[:FOR_TEAM]->(team)
optional match (app)<-[type:OFF|:ON]-(sub)-[:OFF|:ON]->()<-[:MADE_APPEARANCE]-(other)
RETURN team.name AS team, player.name, type(type) AS subbed, other.name, sub.time
ORDER BY team, subbed DESC

// what did the subs get up to?
match (player:Player {name: "Pedro"})-[:MADE_APPEARANCE]->(app)--(event:Event)
WHERE (app)<-[:ON]-()
return player.name, event.time, event.location, [ label in  LABELS(event) where label <> "Event"] AS eventType
ORDER BY event.sortableTime
