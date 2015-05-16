import re
import csv

from extractor import extract_events

def find_foul_location(foul):
    return re.findall(".*free kick (.*)", foul)[0]


match_id = "32683310"
timed_events = extract_events("data/%s" % (match_id))

with open("data/events.csv", "w") as file:
    writer = csv.writer(file, delimiter=",")
    writer.writerow(["matchId",
                     "foulId",
                     "freeKickId",
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
                foul_location = find_foul_location(previous["event"])

                fouled_player = re.findall("([^(]*)", previous["event"])[0].strip()
                fouled_player_team = re.findall(".*\((.*)\)", previous["event"])[0].strip()

                fouling_player = re.findall("Foul by ([^(]*)", entry["event"])[0].strip()
                fouling_player_team = re.findall(".*\((.*)\)", entry["event"])[0].strip()

                values = [match_id,
                          event_id,
                          str(i-1),
                          previous["time"],
                          foul_location,
                          fouled_player,
                          fouled_player_team,
                          fouling_player,
                          fouling_player_team]
                writer.writerow([value.encode("utf-8") for value in values])

            if next["time"] == entry["time"]:
                foul_location = find_foul_location(next["event"])

                fouled_player = re.findall("([^(]*)", next["event"])[0].strip()
                fouled_player_team = re.findall(".*\((.*)\)", next["event"])[0].strip()

                fouling_player = re.findall("Foul by ([^(]*)", entry["event"])[0].strip()
                fouling_player_team = re.findall(".*\((.*)\)", entry["event"])[0].strip()

                values = [match_id,
                          event_id,
                          str(i+1),
                          next["time"],
                          foul_location,
                          fouled_player,
                          fouled_player_team,
                          fouling_player,
                          fouling_player_team]
                writer.writerow([value.encode("utf-8") for value in values])
