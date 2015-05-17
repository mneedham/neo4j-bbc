import re
import csv
from extractor import *

match_id = "32683310"
timed_events = extract_events("data/%s" % (match_id))

players = set()
with open("data/players.csv", "w") as file:
    writer = csv.writer(file, delimiter=",")
    writer.writerow(["matchId",
                     "player",
                     "playerTeam"])

    for i in range(0, len(timed_events)):
        event_id = str(i)
        entry = timed_events[i]
        event = entry["event"]

        foul = re.findall("Foul by.*", event)
        if foul:
            player = fouling_player(entry["event"])
            team = fouling_player_team(entry["event"])
            players.add((player, team))

            previous = timed_events[i-1]
            next = timed_events[i+1]

            if previous["time"] == entry["time"]:
                fouled = previous

            if next["time"] == entry["time"]:
                fouled = next

            player = fouled_player(fouled["event"])
            team = fouled_player_team(fouled["event"])
            players.add((player, team))

print players
print len(players)
