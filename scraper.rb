# frozen_string_literal: true
# #!/bin/env ruby
# encoding: utf-8

require 'pry'
require 'scraped'
require 'scraperwiki'
require 'nokogiri'
require 'scraped_page_archive/open-uri'
require 'date'
require 'scraped'

# require 'open-uri/cached'
# OpenURI::Cache.cache_path = '.cache'
require 'scraped_page_archive/open-uri'

require_rel 'lib'

def scrape(h)
  url, klass = h.to_a.first
  klass.new(response: Scraped::Request.new(url: url).response)
end

list_url = 'http://www.legco.gov.hk/general/english/members/yr16-20/biographies.htm'
(scrape list_url => MembersPage).member_urls.each do |url|
  data = (scrape url => MemberPage).to_h.merge(term: 6)
  ScraperWiki.save_sqlite([:id], data)
  # puts data.reject { |k, v| v.to_s.empty? }.sort_by { |k, v| k }.to_h
end
