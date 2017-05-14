# frozen_string_literal: true

require 'scraped'

# This class represents a page listing members of the given legislature
class MembersPage < Scraped::HTML
  decorator Scraped::Response::Decorator::CleanUrls

  field :member_urls do
    noko.css('.bio-member-detail-1 a/@href').map(&:text)
  end
end
