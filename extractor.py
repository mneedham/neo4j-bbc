from bs4 import BeautifulSoup
from soupselect import select

import bs4
import re
import itertools

def format_time(raw_events):
    raw_events = iter(raw_events)
    for event in raw_events:
        time = event["time"]
        event["formatted_time"] = " +".join(time)

        minutes = seconds = 0
        for chunk in time:
            mins, secs = chunk.split(":")
            minutes += int(mins)
            seconds += int(secs)

        sortable_time = (minutes * 60) + seconds
        event["sortable_time"] = sortable_time
        del event["time"]
        yield event

def raw_events(file):
    match = open(file, 'r')
    soup = BeautifulSoup(match.read())
    events = select(soup, 'div#live-text-commentary-wrapper div#live-text')
    more_events = select(soup, 'div#live-text-commentary-wrapper div#more-live-text')
    for event in events + more_events:
        for child in event.children:
            if type(child) is bs4.element.Tag:
                yield child.getText().strip()

def extract_events(file):
    events = raw_events(file)
    for event in events:
        time =  re.findall("\d{1,2}:\d{2}", event)
        if time:
            yield {'match_id': file.split("/")[2], 'time': time, 'event': next(events)}

def fouls(events):
    events = iter(events)
    event_id = 0
    prev = None
    item = events.next()
    for next in events:
        foul = re.findall("Foul by.*", item["event"])
        if foul:
            if prev["formatted_time"] == item["formatted_time"]:
                fouled = prev
            if next["formatted_time"] == item["formatted_time"]:
                fouled = next

            yield str(event_id), item, fouled
        prev = item
        item = next
        event_id += 1

def attempts(events):
    events = iter(events)
    for event_id, item in enumerate(events):
        event = item["event"]

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

            yield str(event_id), item, outcome, player_with_attempt, player_with_attempt_team, player_with_assist

def corners(events):
    events = iter(events)
    event_id = 0
    item = events.next()

    for next in events:
        event = item["event"]
        corner = re.findall("Corner,", event)

        if corner:
            team = re.findall("Corner, (.*)\. ", event)[0].encode("utf-8").strip()
            conceded_by = re.findall(".*Conceded by (.*)\.", event)[0].encode("utf-8").strip()

            potential_attempt = re.findall("Attempt.*", next["event"])
            if potential_attempt:
                yield str(event_id + 1), str(event_id), team, conceded_by, item
            else:
                yield '', str(event_id), team, conceded_by, item
        item = next
        event_id += 1

def cards(events):
    events = iter(events)

    item = events.next()
    next = events.next()
    event_id = 0

    for next_next in events:
        event = item["event"]
        booking = re.findall("Booking.*", event)
        if booking:
            associated_foul = [x
                               for x in [(next, event_id+1), (next_next, event_id+2)]
                               if re.findall("Foul by.*", x[0]["event"])][0]

            player = re.findall("Booking([^(]*)", event)[0].strip()
            team = re.findall("Booking([^(]*) \((.*)\)", event)[0][1]

            yield event_id, associated_foul[1], player, team, item

        item = next
        next = next_next
        event_id += 1

def subs(events):
    events = iter(events)

    for event_id, event in enumerate(events):
        sub = re.findall("Substitution", event["event"])
        if sub:
            parts = re.findall("Substitution, (.*)\.(.*) replaces (.*)\.$", event["event"])[0]
            team = parts[0]
            on = parts[1].strip()
            off = parts[2].strip()

            yield event_id, team, on, off, event

def foul_location(foul):
    return re.findall(".*free kick (.*)", foul)[0]

def fouled_player(foul):
    return re.findall("([^(]*)", foul)[0].strip()

def fouled_player_team(foul):
    return re.findall(".*\((.*)\)", foul)[0].strip()

def fouling_player(foul):
    return re.findall("Foul by ([^(]*)", foul)[0].strip()

def fouling_player_team(foul):
    return re.findall(".*\((.*)\)", foul)[0].strip()
