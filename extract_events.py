import re
import csv
from extractor import *

match_id = "32683310"
timed_events = extract_events("data/%s" % (match_id))

with open("data/fouls.csv", "w") as file:
    writer = csv.writer(file, delimiter=",")
    writer.writerow(["matchId",
                     "foulId",
                     "time",
                     "foulLocation",
                     "fouledPlayer",
                     "fouledPlayerTeam",
                     "foulingPlayer",
                     "foulingPlayerTeam"])

    for i in range(0, len(timed_events)):
        event_id = str(i)
        entry = timed_events[i]
        event = entry["event"]

        foul = re.findall("Foul by.*", event)
        if foul:
            previous = timed_events[i-1]
            next = timed_events[i+1]

            if previous["time"] == entry["time"]:
                fouled = previous

            if next["time"] == entry["time"]:
                fouled = next

            values = [match_id,
                      event_id,
                      previous["time"],
                      foul_location(fouled["event"]),
                      fouled_player(fouled["event"]),
                      fouled_player_team(fouled["event"]),
                      fouling_player(entry["event"]),
                      fouling_player_team(entry["event"])]
            writer.writerow([value.encode("utf-8") for value in values])

with open("data/attempts.csv", "w") as file:
    writer = csv.writer(file, delimiter=",")
    writer.writerow(["matchId",
                     "attemptId",
                     "time",
                     "attemptOutcome",
                     "attemptBy",
                     "attemptByTeam"])

    for i in range(0, len(timed_events)):
        event_id = str(i)
        entry = timed_events[i]
        event = entry["event"]

        attempt = re.findall("(Attempt|Goal).*", event)
        if attempt:
            print entry
            outcome = re.findall("Attempt ([^\.]*)\.", event)
            player_with_attempt = re.findall(".*\.([^(]*) \(.*\)", event)[0].strip()
            player_with_attempt_team = re.findall(".*\.([^(]*) \((.*)\)", event)[0][1]

            if not outcome:
                outcome = "goal"
            else:
                outcome = outcome[0]

            values = [match_id,
                      event_id,
                      entry["time"],
                      outcome,
                      player_with_attempt,
                      player_with_attempt_team]
            writer.writerow([value.encode("utf-8") for value in values])
