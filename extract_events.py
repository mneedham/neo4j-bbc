import bs4
import re

from bs4 import BeautifulSoup
from soupselect import select

match = open("data/32683310", 'r')
soup = BeautifulSoup(match.read())

all_events = []

for event in select(soup, 'div#live-text-commentary-wrapper div#live-text'):
    for child in event.children:
        if type(child) is bs4.element.Tag:
            all_events.append(child.getText().strip())

for event in select(soup, 'div#live-text-commentary-wrapper div#more-live-text'):
    for child in event.children:
        if type(child) is bs4.element.Tag:
            all_events.append(child.getText().strip())

indexed_events = list(enumerate(all_events))

timed_events = []
for i in range(0, len(indexed_events)):
    idx, event = indexed_events[i]
    time =  re.findall("\d{1,2}:\d{2}", event)
    formatted_time = " +".join(time)
    if time:
        timed_events.append({'time': formatted_time, 'event': indexed_events[i+1][1]})

for i in range(0, len(timed_events)):
    entry = timed_events[i]
    event = entry["event"]

    foul = re.findall("Foul by.*", event)
    if foul:
        previous = timed_events[i-1]
        next = timed_events[i+1]

        if previous["time"] == entry["time"]:
            print [previous, entry]
        if next["time"] == entry["time"]:
            print [next, entry]
