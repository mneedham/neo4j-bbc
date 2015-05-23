import re
import csv
from extractor import *
import itertools

match_id = "32683310"
timed_events = list(extract_events("data/%s" % (match_id)))

with open("data/fouls.csv", "w") as file:
    writer = csv.writer(file, delimiter=",")
    writer.writerow(["matchId", "foulId", "time", "foulLocation", "fouledPlayer",
                     "fouledPlayerTeam", "foulingPlayer", "foulingPlayerTeam"])

    for event_id, entry, fouled in fouls(timed_events):
        values = [match_id, event_id, fouled["time"], foul_location(fouled["event"]),
                  fouled_player(fouled["event"]), fouled_player_team(fouled["event"]),
                  fouling_player(entry["event"]), fouling_player_team(entry["event"])]
        writer.writerow([value.encode("utf-8") for value in values])

with open("data/attempts.csv", "w") as file:
    writer = csv.writer(file, delimiter=",")
    writer.writerow(["matchId", "attemptId", "time", "attemptOutcome",
                     "attemptBy", "attemptByTeam", "assistedBy"])

    for event_id, time, outcome, attempt, team, assist in attempts(timed_events):
        values = [match_id, event_id, time, outcome, attempt,team, assist]
        writer.writerow([value.encode("utf-8") for value in values])

with open("data/corners.csv", "w") as file:
    writer = csv.writer(file, delimiter=",")
    writer.writerow(["matchId", "attemptId", "cornerId", "team", "concededBy"])

    for attempt_id, corner_id, team, conceded_by in corners(timed_events):
        writer.writerow([match_id, attempt_id, corner_id, team, conceded_by])

with open("data/cards.csv", "w") as file:
    writer = csv.writer(file, delimiter=",")
    writer.writerow(["matchId", "cardId", "foulId", "player", "playerTeam"])

    for card_id, associated_foul, player, team in cards(timed_events):
        writer.writerow([match_id, card_id, associated_foul, player.encode('utf-8'), team.encode('utf-8')])

    # for i in range(0, len(timed_events)):
    #     event_id = str(i)
    #     entry = timed_events[i]
    #     event = entry["event"]
    #     booking = re.findall("Booking.*", event)
    #
    #     if booking:
    #         associated_foul = [(timed_events[j]["event"], j)
    #                             for j in [i+1,i+2]
    #                             if re.findall("Foul by.*", timed_events[j]["event"])][0]
    #
    #         player = re.findall("Booking([^(]*)", event)[0].strip()
    #         team = re.findall("Booking([^(]*) \((.*)\)", event)[0][1]
    #         writer.writerow([match_id, i, associated_foul[1], player.encode('utf-8'), team.encode('utf-8')])
