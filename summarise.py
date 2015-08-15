import re
import sys
from tabulate import tabulate

lines = sys.stdin.readlines()

def search(term, line):
    m =  re.match(term + ": (.*)", line)
    return (int(m.group(1)) if m else 0)

nodes_created, relationships_created, constraints_added, indexes_added, labels_added, properties_set = 0, 0, 0, 0, 0, 0
for line in lines:
    nodes_created = nodes_created + search("Nodes created", line)
    relationships_created = relationships_created + search("Relationships created", line)
    constraints_added = constraints_added + search("Constraints added", line)
    indexes_added = indexes_added + search("Indexes added", line)
    labels_added = labels_added + search("Labels added", line)
    properties_set = properties_set + search("Properties set", line)

    time_match = re.match("real.*([0-9]+m[0-9]+\.[0-9]+s)$", line)

    if time_match:
        time = time_match.group(1)

table = [
            ["Constraints added", constraints_added],
            ["Indexes added", indexes_added],
            ["Nodes created", nodes_created],
            ["Relationships created", relationships_created],
            ["Labels added", labels_added],
            ["Properties set", properties_set],
            ["Time", time]
         ]
print tabulate(table)
