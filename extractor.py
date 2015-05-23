from bs4 import BeautifulSoup
from soupselect import select

import bs4
import re

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
        formatted_time = " +".join(time)
        if time:
            yield {'time': formatted_time, 'event': next(events)}

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
