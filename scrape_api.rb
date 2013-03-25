# scrape new stories from the unofficial hacker news api
# the API is broken half the time, so this needs to be made more robust

require 'nokogiri'
require 'open-uri'
require 'json'
require_relative "story"
require_relative "utils"
require_relative "model"

puts Time.now

def scrape()
  new_stories = []
  found_known_story = false
  model = Model.load

  doc = Nokogiri::HTML(open("https://news.ycombinator.com/newest"))
  doc.xpath("//td[@class='title']/a").each do |node|
    url = node.attr("href")
    if /^item/.match(url)
        url = "http://news.ycombinator.com/" + url
    end
    if /^\/x/.match(url)
        next
    end
    title = node.text
    subtext = node.parent.parent.next.xpath(".//td[@class='subtext']")
    # score = subtext.xpath(".//span").text
    user = subtext.xpath(".//a").first.text
    id = subtext.xpath(".//a").last.attr("href").sub(/item\?id=/, '').to_i
    # time = subtext.children[3].text.sub(/^ +(.*) +\| +/, '\1')

    if Story.where(:hnid => id).count > 0
      found_known_story = true
      puts "known story: #{id}"
    else
      story = Story.new
      story.hnid = id
      story.link_url = url
      story.link_title = title
      story.domain = domain(url)
      story.scraped_at = Time.now
      story.user = user
      story.prediction = model.classify(story) if model
      new_stories << story
    end

    break if found_known_story
  end

  puts "found #{new_stories.size} new stories"
  new_stories.each do |s|
    s.save
  end
end


scrape()
