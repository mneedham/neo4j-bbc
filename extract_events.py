import re
import csv
from extractor import *
import itertools

match_id = "32683310"
timed_events = extract_events("data/%s" % (match_id))

# for event in timed_events:
#     print event
#
# import sys
# sys.exit(1)

# with open("data/fouls.csv", "w") as file:
#     writer = csv.writer(file, delimiter=",")
#     writer.writerow(["matchId", "foulId", "time", "foulLocation", "fouledPlayer",
#                      "fouledPlayerTeam", "foulingPlayer", "foulingPlayerTeam"])
#
#     for i in range(0, len(timed_events)):
#         event_id = str(i)
#         entry = timed_events[i]
#         event = entry["event"]
#
#         foul = re.findall("Foul by.*", event)
#         if foul:
#             previous = timed_events[i-1]
#             next = timed_events[i+1]
#
#             if previous["time"] == entry["time"]:
#                 fouled = previous
#
#             if next["time"] == entry["time"]:
#                 fouled = next
#
#             values = [match_id, event_id, fouled["time"], foul_location(fouled["event"]),
#                       fouled_player(fouled["event"]), fouled_player_team(fouled["event"]),
#                       fouling_player(entry["event"]), fouling_player_team(entry["event"])]
#             writer.writerow([value.encode("utf-8") for value in values])

with open("data/attempts.csv", "w") as file:
    writer = csv.writer(file, delimiter=",")
    writer.writerow(["matchId", "attemptId", "time",
                     "attemptOutcome", "attemptBy", "attemptByTeam",
                     "assistedBy"])

    for i in range(0, len(timed_events)):
        event_id = str(i)
        entry = timed_events[i]
        event = entry["event"]

        attempt = re.findall("(Attempt|Goal).*", event)
        if attempt:
            outcome = re.findall("Attempt ([^\.]*)\.", event)
            player_with_attempt = re.findall(".*\.([^(]*) \(.*\)", event)[0].strip()
            player_with_attempt_team = re.findall(".*\.([^(]*) \((.*)\)", event)[0][1]

            if not outcome:
                outcome = "goal"
            else:
                outcome = outcome[0]

            player_with_assist = ""
            parts = re.findall("\. Assisted by ([^\.]*)", event)
            if parts:
                without_with =  list(itertools.takewhile(lambda word: word != "with" and word != "following", parts[0].split(" ")))
                player_with_assist = " ".join(without_with)

            values = [match_id,
                      event_id,
                      entry["time"],
                      outcome,
                      player_with_attempt,
                      player_with_attempt_team,
                      player_with_assist]
            writer.writerow([value.encode("utf-8") for value in values])

# with open("data/corners.csv", "w") as file:
#     writer = csv.writer(file, delimiter=",")
#     writer.writerow(["matchId", "attemptId", "cornerId", "team", "concededBy"])
#
#     for i in range(0, len(timed_events)):
#         event_id = str(i)
#         entry = timed_events[i]
#         event = entry["event"]
#         corner = re.findall("Corner,", event)
#
#         if corner:
#             team = re.findall("Corner, (.*)\. ", event)[0].encode("utf-8").strip()
#             conceded_by = re.findall(".*Conceded by (.*)\.", event)[0].encode("utf-8").strip()
#
#             potential_attempt = re.findall("Attempt.*", timed_events[i+1]["event"])
#             if potential_attempt:
#                 writer.writerow([match_id, str(i+1), str(i), team, conceded_by])
#             else:
#                 writer.writerow([match_id, '', str(i), team, conceded_by])

# with open("data/cards.csv", "w") as file:
#     writer = csv.writer(file, delimiter=",")
#     writer.writerow(["matchId", "cardId", "foulId", "player", "playerTeam"])
#
#     for i in range(0, len(timed_events)):
#         event_id = str(i)
#         entry = timed_events[i]
#         event = entry["event"]
#         booking = re.findall("Booking.*", event)
#
#         if booking:
#             associated_foul = [(timed_events[j]["event"], j)
#                                 for j in [i+1,i+2]
#                                 if re.findall("Foul by.*", timed_events[j]["event"])][0]
#
#             player = re.findall("Booking([^(]*)", event)[0].strip()
#             team = re.findall("Booking([^(]*) \((.*)\)", event)[0][1]
#             writer.writerow([match_id, i, associated_foul[1], player.encode('utf-8'), team.encode('utf-8')])
