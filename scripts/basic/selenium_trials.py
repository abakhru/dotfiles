#!/usr/bin/python

import selenium
import time
from selenium import webdriver
from selenium.common.exceptions import NoSuchElementException
from selenium.webdriver.common.keys import Keys

browser = webdriver.Firefox()  # Get local session of firefox
browser.get("https://localhost:15672/")  # Load page
assert "RabbitMQ Management" in browser.title
elem = browser.find_element_by_name("p")  # Find the query box
elem.send_keys("seleniumhq" + Keys.RETURN)
time.sleep(2)  # Let the page load, will be added to the API
try:
    browser.find_element_by_xpath("//a[contains(@href,'http://seleniumhq.org')]")
except NoSuchElementException:
    assert 0, "can't find seleniumhq"
    browser.close()
