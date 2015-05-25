import re
import csv
from extractor import *
import itertools

# matches = ["32683310", "32683303"]
matches = ["32683310", "32683303", "32384894", "31816155"]

raw_events = itertools.chain()
for match_id in matches:
    raw_events = itertools.chain(raw_events, extract_events("data/raw/%s" % (match_id)))

timed_events = list(format_time(raw_events))

# for event in timed_events:
#     print event
#

match_id = "32683310"
events = extract_events("data/raw/%s" % (match_id))
# print type(events)
#
# import sys
# sys.exit(1)

with open("data/fouls.csv", "w") as file:
    writer = csv.writer(file, delimiter=",")
    writer.writerow(["matchId", "foulId", "time", "foulLocation", "fouledPlayer",
                     "fouledPlayerTeam", "foulingPlayer", "foulingPlayerTeam",
                     "sortableTime"])

    for event_id, entry, fouled in fouls(timed_events):
        values = [fouled["match_id"], event_id, fouled["formatted_time"], foul_location(fouled["event"]),
                  fouled_player(fouled["event"]), fouled_player_team(fouled["event"]),
                  fouling_player(entry["event"]), fouling_player_team(entry["event"])]
        writer.writerow([value.encode("utf-8") for value in values] + [fouled["sortable_time"]])

with open("data/attempts.csv", "w") as file:
    writer = csv.writer(file, delimiter=",")
    writer.writerow(["matchId", "attemptId", "time", "attemptOutcome",
                     "attemptBy", "attemptByTeam", "assistedBy", "sortableTime"])

    for event_id, item, outcome, attempt, team, assist in attempts(timed_events):
        values = [item["match_id"], event_id, item["formatted_time"], outcome, attempt,team, assist]
        writer.writerow([value.encode("utf-8") for value in values] + [item["sortable_time"]])

with open("data/corners.csv", "w") as file:
    writer = csv.writer(file, delimiter=",")
    writer.writerow(["matchId", "attemptId", "cornerId", "team", "concededBy", "time", "sortableTime"])

    for attempt_id, corner_id, team, conceded_by, item  in corners(timed_events):
        writer.writerow([item["match_id"], attempt_id, corner_id, team, conceded_by, item["formatted_time"], item["sortable_time"]])

with open("data/cards.csv", "w") as file:
    writer = csv.writer(file, delimiter=",")
    writer.writerow(["matchId", "cardId", "foulId", "player", "playerTeam", "time", "sortableTime", "cardType"])

    for card_id, associated_foul, player, team, item, card_type in cards(timed_events):
        writer.writerow([item["match_id"], card_id, associated_foul, player.encode('utf-8'), team.encode('utf-8'), item["formatted_time"], item["sortable_time"], card_type])

with open("data/subs.csv", "w") as file:
    writer = csv.writer(file, delimiter=",")
    writer.writerow(["matchId", "subId", "team", "on", "off", "time", "sortableTime"])

    for event_id, team, on, off, event in subs(timed_events):
        writer.writerow([event["match_id"], event_id, team.encode("utf-8"), on.encode("utf-8"), off.encode("utf-8"), event["formatted_time"], event["sortable_time"]])
