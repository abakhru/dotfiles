from scrapy.spiders import Spider
from craigslist.items import CraigslistItem


class MySpider(Spider):
    name = "craigslist"
    allowed_domains = ["code.tutsplus.com"]
    start_urls = ["http://code.tutsplus.com/"]

    def parse(self, response):
        titles = response.xpath('//a[contains(@class, "posts__post-title")]/h1/text()').extract()
        for title in titles:
            item = CraigslistItem()
            item["title"] = title
            yield item
