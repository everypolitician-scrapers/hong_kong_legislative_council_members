# #!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'open-uri/cached'
require 'date'

OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_list(url)
  noko = noko_for(url)
  noko.css('.bio-member-detail-1 a/@href').each do |link|
    bio = URI.join(url, link.to_s)
    scrape_person(bio)
  end
end

def process_area(area)
  area_info = {}

  area_info[:area_type] = 'functional' if area.index('Functional')
  area_info[:area_type] = 'geographical' if area.index('Geographical')
  area_info[:area] = area.gsub(/.*(?:Geographical|Functional)\s+Constituency\s+[–-]\s+/, '').tidy

  return area_info
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
    name = $2
    honorific_prefix = $1
  end
  name = name.tidy
  honorific_prefix = honorific_prefix.tidy if honorific_prefix

  gender = '';
  gender = 'female' if honorific_prefix.index('Mrs')

  name_suffix = name_parts.join(', ').tidy

  img = URI.join(url, bio.css('img/@src').to_s).to_s

  area = bio.xpath('//p[contains(.,"Constituency")]/following-sibling::ul[not(position() > 1)]/li/text()').to_s
  area_info = process_area(area)

  faction = bio.xpath('//p[contains(.,"Political affiliation")]/following-sibling::ul[not(position() > 1)]/li/text()').to_s.tidy

  email = bio.xpath('//table/tr/td/a[contains(@href, "mailto")]/text()').to_s.tidy

  website = bio.xpath('//table/tr/td[contains(.,"Homepage")]/following-sibling::td/a/text()').to_s.tidy
  phone = bio.xpath('//table/tr/td[contains(.,"telephone")]/following-sibling::td[position() = 2]/text()').to_s.tidy
  fax = bio.xpath('//table/tr/td[contains(.,"fax")]/following-sibling::td[position() = 2]/text()').to_s.tidy

  data = {
    id: id,
    term: 5,
    name: name,
    honorific_suffix: name_suffix,
    honorific_prefix: honorific_prefix,
    img: img,
    faction: faction,
    email: email,
    website: website,
    phone: phone,
    fax: fax,
    gender: gender,
    source: url.to_s
  }

  data = data.merge(area_info)

  ScraperWiki.save_sqlite([:id], data)
end

term = {
  id: 5,
  name: 'Fifth Legislative Council',
  start_date: '2012-09-12',
  source: 'http://www.legco.gov.hk/general/english/intro/hist_lc.htm',
}

ScraperWiki.save_sqlite([:id], term, 'terms')

scrape_list('http://www.legco.gov.hk/general/english/members/yr12-16/biographies.htm')
