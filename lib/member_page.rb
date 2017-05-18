# frozen_string_literal: true

require 'scraped'
require 'pry'

# This class represents the profile page of a given member
class MemberPage < Scraped::HTML
  decorator Scraped::Response::Decorator::CleanUrls

  field :id do
    url.gsub('.htm', '').split('members/').last
  end

  field :name do
    name_parts.first.to_s.gsub(Regexp.union(titles << '.'), '').tidy
  end

  field :honorific_prefix do
    titles.select { |prefix| name_parts.first.to_s.include? prefix }.join(' ')
  end

  field :honorific_suffix do
    name_parts[1..-1].map(&:tidy).join(', ')
  end

  field :gender do
    return 'female' if honorific_prefix.include?('Mrs')
  end

  field :faction do
    f = bio.xpath('//p[contains(.,"Political affiliation")]/'\
                  'following-sibling::ul[not(position() > 1)]/li/text()')
    return 'Independent' if f.empty?

    # Some member pages list more than one group affiliation for that member
    # Here, we remove affiliations with known non-party groups
    f.map(&:to_s).map(&:tidy).find do |party|
      !non_party_groups.to_s.include? party
    end
  end

  field :email do
    bio.xpath('//table/tr/td/a[contains(@href, "mailto")]/text()').to_s.tidy
  end

  field :website do
    bio.xpath('//table/tr/td[contains(.,"Homepage")]/following-sibling::'\
              'td/a/text()').to_s.tidy
  end

  field :phone do
    bio.xpath('//table/tr/td[contains(.,"telephone")]/following-sibling::'\
              'td[position() = 2]/text()').to_s.tidy
  end

  field :fax do
    bio.xpath('//table/tr/td[contains(.,"fax")]/following-sibling::'\
              'td[position() = 2]/text()').to_s.tidy
  end

  field :img do
    # TODO: incorrect image being captured for 'WONG Ting-kwong'
    # Change line to: bio.at_css('img/@src').to_s
    bio.css('img/@src').last.to_s
  end

  field :area do
    # splitting here by en-dash (not hyphen)
    area_parts.last.split('–').last.tidy
  end

  field :area_type do
    return 'functional' if area_parts.first.include?('Functional')
    return 'geographical' if area_parts.first.include?('Geographical')
    area_parts.first
  end

  field :source do
    url
  end

  private

  def area_parts
    bio.xpath('//p[contains(.,"Constituency")]/following-sibling'\
              '::ul[not(position() > 1)]/li/text()').to_s.split('-')
  end

  def name_parts
    bio.css('h2').text.split(',')
  end

  def titles
    %w[Ir Dr Prof Hon Mrs]
  end

  def bio
    noko.css('div#container div')
  end

  def non_party_groups
    [
      'Kowloon West New Dynamic',
      'New Territories Association of Societies',
      'April Fifth Action',
    ]
  end
end
