# frozen_string_literal: true

require 'scraped'

# This class represents the profile page of a given member
class MemberPage < Scraped::HTML
  decorator Scraped::Response::Decorator::CleanUrls

  field :id do
    [term, File.basename(url, '.htm')].join('/')
  end

  field :term do
    File.dirname(url).split('/').last
  end

  field :name do
    (name_without_suffixes.split - titles).join(' ')
  end

  field :honorific_prefix do
    (name_without_suffixes.split & titles).join(' ')
  end

  field :honorific_suffix do
    suffixes.join(', ')
  end

  field :gender do
    return 'female' if honorific_prefix.include?('Mrs')
  end

  field :faction do
    return 'Independent' if political_affiliation.empty?
    # Some member pages list more than one group affiliation for that member
    # Here, we remove affiliations with known non-party groups
    (political_affiliation - non_party_groups).first
  end

  field :email do
    bio.xpath('//table/tr/td/a[contains(@href, "mailto")]').map(&:text).map(&:tidy).join(';')
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
    area_parts.last.split("\u{2013}").last.tidy
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

  def name_text
    bio.css('h2').text
  end

  def name_without_suffixes
    name_text.split(',').first
  end

  def suffixes
    name_text.split(',').drop(1).map(&:tidy)
  end

  def titles
    %w[Ir Dr Prof Hon Mrs]
  end

  def bio
    noko.css('div#container div')
  end

  def non_party_groups
    Set[
      'Kowloon West New Dynamic',
      'New Territories Association of Societies',
      'April Fifth Action',
    ]
  end

  def political_affiliation
    bio.xpath('//p[contains(.,"Political affiliation")]/'\
                  'following-sibling::ul[not(position() > 1)]/li/text()')
       .map(&:to_s)
       .map(&:tidy)
       .to_set
  end
end
