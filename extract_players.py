# encoding=utf8
import sys
reload(sys)
sys.setdefaultencoding('utf8')

import re
import csv
import itertools

from extractor import *
from collections import defaultdict

import os, glob
matches = [f.split("/")[-1] for f in glob.glob('data/raw/[0-9]*') if os.path.isfile(f) ]
# matches = ["32683310", "32683303"]
# matches = ["32683310", "32683303", "32384894", "31816155"]

raw_events = itertools.chain()
for match_id in matches:
    raw_events = itertools.chain(raw_events, extract_events("data/raw/%s" % (match_id)))
timed_events = list(format_time(raw_events))

players = set()
players_matches = defaultdict(set)
matches_teams = defaultdict(set)

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

        if previous["formatted_time"] == entry["formatted_time"]:
            fouled = previous

        if next["formatted_time"] == entry["formatted_time"]:
            fouled = next

        player = fouled_player(fouled["event"]).encode("utf-8")
        team = fouled_player_team(fouled["event"])

        players_matches[(player, team)].add(entry["match_id"])
        players.add((player, team))
        matches_teams[entry["match_id"]].add(team)

for i in range(0, len(timed_events)):
    entry = timed_events[i]
    event = entry["event"]

    sub = re.findall("Substitution", event)

    if sub:
        parts = re.findall("Substitution, (.*)\.(.*) replaces (.*)\.$", event)[0]
        team = parts[0]
        on = parts[1].strip().encode("utf-8")
        off = parts[2].strip().encode("utf-8").replace("because of an injury", "")

        players.add((on, team))
        players_matches[(on, team)].add(entry["match_id"])

        players.add((off, team))
        players_matches[(off, team)].add(entry["match_id"])

        matches_teams[entry["match_id"]].add(team)

for i in range(0, len(timed_events)):
    entry = timed_events[i]
    event = entry["event"]

    teams = matches_teams[entry["match_id"]]

    corner = re.findall("Corner,", event)
    if corner:
        other_team = re.findall("Corner, (.*)\. ", event)[0].encode("utf-8").strip()
        conceded_by = re.findall(".*Conceded by (.*)\.", event)[0].encode("utf-8").strip()
        team = list(teams.difference([other_team]))[0]

        players.add((conceded_by, team))
        players_matches[(conceded_by, team)].add(entry["match_id"])

import sys
for player in players:
    print player

sys.exit(1)

with open("data/players.csv", "w") as file:
    writer = csv.writer(file, delimiter=",")
    writer.writerow(["matchId", "player", "team"])

    for player, team in players:
        matches = players_matches[(player, team)]

        for match_id in matches:
            writer.writerow([match_id, player, team])
