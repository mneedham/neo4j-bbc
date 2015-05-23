import re
import csv
from extractor import *
import itertools

match_id = "32683310"
raw_events = extract_events("data/raw/%s" % (match_id))
timed_events = list(format_time(raw_events))

with open("data/fouls.csv", "w") as file:
    writer = csv.writer(file, delimiter=",")
    writer.writerow(["matchId", "foulId", "time", "foulLocation", "fouledPlayer",
                     "fouledPlayerTeam", "foulingPlayer", "foulingPlayerTeam",
                     "sortableTime"])

    for event_id, entry, fouled in fouls(timed_events):
        values = [match_id, event_id, fouled["formatted_time"], foul_location(fouled["event"]),
                  fouled_player(fouled["event"]), fouled_player_team(fouled["event"]),
                  fouling_player(entry["event"]), fouling_player_team(entry["event"])]
        writer.writerow([value.encode("utf-8") for value in values] + [fouled["sortable_time"]])

with open("data/attempts.csv", "w") as file:
    writer = csv.writer(file, delimiter=",")
    writer.writerow(["matchId", "attemptId", "time", "attemptOutcome",
                     "attemptBy", "attemptByTeam", "assistedBy", "sortableTime"])

    for event_id, time, outcome, attempt, team, assist, sortable_time in attempts(timed_events):
        values = [match_id, event_id, time, outcome, attempt,team, assist]
        writer.writerow([value.encode("utf-8") for value in values] + [sortable_time])

with open("data/corners.csv", "w") as file:
    writer = csv.writer(file, delimiter=",")
    writer.writerow(["matchId", "attemptId", "cornerId", "team", "concededBy", "time", "sortableTime"])

    for attempt_id, corner_id, team, conceded_by, time, sortable_time in corners(timed_events):
        writer.writerow([match_id, attempt_id, corner_id, team, conceded_by, time, sortable_time])

with open("data/cards.csv", "w") as file:
    writer = csv.writer(file, delimiter=",")
    writer.writerow(["matchId", "cardId", "foulId", "player", "playerTeam", "time", "sortableTime"])

    for card_id, associated_foul, player, team, time, sortable_time in cards(timed_events):
        writer.writerow([match_id, card_id, associated_foul, player.encode('utf-8'), team.encode('utf-8'), time, sortable_time])

with open("data/subs.csv", "w") as file:
    writer = csv.writer(file, delimiter=",")
    writer.writerow(["matchId", "subId", "team", "on", "off", "time", "sortableTime"])

    for event_id, team, on, off, time, sortable_time in subs(timed_events):
        writer.writerow([match_id, event_id, team.encode("utf-8"), on.encode("utf-8"), off.encode("utf-8"), time, sortable_time])
