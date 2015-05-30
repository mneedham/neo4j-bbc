from bs4 import BeautifulSoup
from soupselect import select
import bs4

soup = BeautifulSoup(open("data/raw/results", "r"))

matches = select(soup, "a.report")

for match in matches:
    print "http://www.bbc.co.uk/%s" %(match.get("href"))
