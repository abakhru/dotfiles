#!/usr/bin/env python

import scrapy
from scrapy import Request
from scrapy.spidermiddlewares import referer
from scrapy.utils import response


class BlogSpider(scrapy.Spider):
    start_urls = ['http://www.businessinsider.com/trump-media-enemy-of-american-people-2017-2']

    def parse(self, response):
        for title in response.css('h2.entry-title'):
            yield {'title': title.css('a ::text').extract_first()}

        next_page = response.css('div.prev-post > a ::attr(href)').extract_first()
        if next_page:
            yield scrapy.Request(response.urljoin(next_page), callback=self.parse)
