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

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'
# require 'scraped_page_archive/open-uri'

require_rel 'lib'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape(h)
  url, klass = h.to_a.first
  klass.new(response: Scraped::Request.new(url: url).response)
end

def process_area(area)
  area_info = {}

  area_info[:area_type] = 'functional' if area.index('Functional')
  area_info[:area_type] = 'geographical' if area.index('Geographical')
  area_info[:area] = area.gsub(/.*(?:Geographical|Functional)\s+Constituency\s+[–-]\s+/, '').tidy

  area_info
end

# if they have two affiliations listed then pick the sensible one where we
# mean the one listed in the breakdown at https://en.wikipedia.org/wiki/Legislative_Council_of_Hong_Kong
def fix_parties(parties)
  return 'Labour Party' if parties.to_s.index('Labour Party')
  return 'Democratic Alliance for the Betterment and Progress of Hong Kong' if parties.to_s.index('Democratic Alliance for the Betterment and Progress of Hong Kong')
  return 'Business and Professionals Alliance for Hong Kong' if parties.to_s.index('Business and Professionals Alliance for Hong Kong')
  return 'People Power' if parties.to_s.index('People Power')
  return 'League of Social Democrats' if parties.to_s.index('League of Social Democrats')

  # fall back to the first one in the list
  parties[0].to_s
end

def scrape_person(url)
  noko = noko_for(url)
  bio = noko.css('div#container div')
  # everything after the comma is qualification letters

  id = url.to_s.gsub(/.*(yr\d\d.*)\.htm/, '\1')

  name_parts = bio.css('h2').text.to_s.split(',')
  name = name_parts.shift.to_s
  honorific_prefix = ''
  name.gsub(/^((?:(?:Hon|Prof|Dr|Ir|Mrs)\s+)+)(.*)$/) do
    name = Regexp.last_match(2)
    honorific_prefix = Regexp.last_match(1)
  end
  name = name.tidy
  honorific_prefix = honorific_prefix.tidy if honorific_prefix

  gender = ''
  gender = 'female' if honorific_prefix.index('Mrs')

  name_suffix = name_parts.join(', ').tidy

  img = URI.join(url, bio.css('img/@src').to_s).to_s

  area = bio.xpath('//p[contains(.,"Constituency")]/following-sibling::ul[not(position() > 1)]/li/text()').to_s
  area_info = process_area(area)

  faction = bio.xpath('//p[contains(.,"Political affiliation")]/following-sibling::ul[not(position() > 1)]/li/text()')
  if faction.size > 1
    faction = fix_parties(faction)
  else
    faction = faction.to_s.tidy
    faction = 'Independent' if faction.empty?
  end

  email = bio.xpath('//table/tr/td/a[contains(@href, "mailto")]/text()').to_s.tidy

  website = bio.xpath('//table/tr/td[contains(.,"Homepage")]/following-sibling::td/a/text()').to_s.tidy
  phone = bio.xpath('//table/tr/td[contains(.,"telephone")]/following-sibling::td[position() = 2]/text()').to_s.tidy
  fax = bio.xpath('//table/tr/td[contains(.,"fax")]/following-sibling::td[position() = 2]/text()').to_s.tidy

  data = {
    id:               id,
    term:             6,
    name:             name,
    honorific_suffix: name_suffix,
    honorific_prefix: honorific_prefix,
    img:              img,
    faction:          faction,
    email:            email,
    website:          website,
    phone:            phone,
    fax:              fax,
    gender:           gender,
    source:           url.to_s,
  }

  data = data.merge(area_info)

  puts data.reject { |k, v| v.to_s.empty? }.sort_by { |k, v| k }.to_h
  ScraperWiki.save_sqlite([:id], data)
end

list_url = "http://www.legco.gov.hk/general/english/members/yr16-20/biographies.htm"
(scrape list_url => MembersPage).member_urls.each { |url| scrape_person(url) }
