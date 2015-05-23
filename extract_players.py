# encoding=utf8
import sys
reload(sys)
sys.setdefaultencoding('utf8')

import re
import csv
from extractor import *

match_id = "32683310"
timed_events = list(extract_events("data/%s" % (match_id)))

players = set()
for i in range(0, len(timed_events)):
    entry = timed_events[i]
    event = entry["event"]

    foul = re.findall("Foul by.*", event)
    if foul:
        player = fouling_player(entry["event"]).encode("utf-8")
        team = fouling_player_team(entry["event"])
        players.add((player, team))

        previous = timed_events[i-1]
        next = timed_events[i+1]

        if previous["time"] == entry["time"]:
            fouled = previous

        if next["time"] == entry["time"]:
            fouled = next

        player = fouled_player(fouled["event"]).encode("utf-8")
        team = fouled_player_team(fouled["event"])
        players.add((player, team))

for i in range(0, len(timed_events)):
    entry = timed_events[i]
    event = entry["event"]

    sub = re.findall("Substitution", event)

    if sub:
        parts = re.findall("Substitution, (.*)\.(.*) replaces (.*)\.$", event)[0]
        team = parts[0]
        on = parts[1].strip().encode("utf-8")
        off = parts[2].strip().encode("utf-8")

        players.add((on, team))
        players.add((off, team))


teams = set([item[1].encode("utf-8") for item in players])
for i in range(0, len(timed_events)):
    entry = timed_events[i]
    event = entry["event"]

    corner = re.findall("Corner,", event)
    if corner:
        other_team = re.findall("Corner, (.*)\. ", event)[0].encode("utf-8").strip()
        conceded_by = re.findall(".*Conceded by (.*)\.", event)[0].encode("utf-8").strip()
        team = list(teams.difference([other_team]))[0]
        players.add((conceded_by, team))

with open("data/players.csv", "w") as file:
    writer = csv.writer(file, delimiter=",")
    writer.writerow(["matchId", "player", "team"])

    for player, team in players:
        writer.writerow([match_id, player, team])
