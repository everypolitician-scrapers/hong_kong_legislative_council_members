# frozen_string_literal: true
# #!/bin/env ruby
# encoding: utf-8

require 'pry'
require 'scraped'
require 'scraperwiki'

# require 'open-uri/cached'
# OpenURI::Cache.cache_path = '.cache'
require 'scraped_page_archive/open-uri'

require_rel 'lib'

def scrape(h)
  url, klass = h.to_a.first
  klass.new(response: Scraped::Request.new(url: url).response)
end

list_url = 'http://www.legco.gov.hk/general/english/members/yr16-20/biographies.htm'
data = (scrape list_url => MembersPage).member_urls.map do |url|
  (scrape url => MemberPage).to_h.merge(term: 6)
  # puts data.reject { |k, v| v.to_s.empty? }.sort_by { |k, v| k }.to_h
end

ScraperWiki.sqliteexecute('DROP TABLE data') rescue nil
ScraperWiki.save_sqlite([:id], data)
