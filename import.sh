#!/bin/sh

{ ./neo4j-community-2.2.3/bin/neo4j stop; } 2>&1
rm -rf neo4j-community-2.2.3/data/graph.db/
{ ./neo4j-community-2.2.3/bin/neo4j start; } 2>&1
{ time ./neo4j-community-2.2.3/bin/neo4j-shell --file $1; } 2>&1
