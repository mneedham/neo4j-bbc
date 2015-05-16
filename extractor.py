from bs4 import BeautifulSoup
from soupselect import select

import bs4
import re

def extract_events(file):
    match = open(file, 'r')
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
    return timed_events
