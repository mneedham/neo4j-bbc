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
