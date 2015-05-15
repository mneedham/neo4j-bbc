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
            # print child.getText()
            all_events.append(child.getText().strip())


for event in select(soup, 'div#live-text-commentary-wrapper div#more-live-text'):
    for child in event.children:
        if type(child) is bs4.element.Tag:
            # print child.getText()
            all_events.append(child.getText().strip())

indexed_events = list(enumerate(all_events))

for i in range(0, len(indexed_events)):
    event = indexed_events[i][1]
    time =  re.findall("\d{1,2}:\d{2}", event)

    if time:
        print " +".join(time), indexed_events[i+1][1]
