from bs4 import BeautifulSoup
from soupselect import select

import bs4
import re
import itertools

soup = BeautifulSoup(open("data/results", "r"))

matches = select(soup, "a.report")

for match in matches:
    print "http://www.bbc.co.uk/%s" %(match.get("href"))
