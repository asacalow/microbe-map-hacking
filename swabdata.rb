require 'rubygems'
require 'nokogiri'
require 'csv'
require 'flickraw'
require 'yaml'

creds = YAML.load_file('flickr.yml')

FlickRaw.api_key = creds['api_key']
FlickRaw.shared_secret = creds['shared_secret']

doc = Nokogiri::XML "<?xml version=\"1.0\" encoding=\"UTF-8\"?><swabdata />"
root = doc.root

team_node = nil
team_number = 0
CSV.foreach("swabdata.csv") do |row|
  tn, letter, name, longlat, dir, dist_th, loc, colonies, types, flickr_url, colour = row
  puts "Processing '#{name.strip}'"
  dir = (dir || '').downcase.include?('in') ? 'in' : 'out'
  if (tn != team_number)
    team_number = tn
    team_node = Nokogiri::XML::Node.new 'team', doc
    team_node['number'] = team_number
    root << team_node
  end
  sample_node = Nokogiri::XML::Node.new 'sample', doc
  team_node << sample_node
  sample_node['letter'] = letter
  sample_node['name'] = name.strip
  sample_node['longlat'] = longlat
  sample_node['dir'] = dir
  sample_node['loc'] = loc || ''
  sample_node['colonies'] = colonies
  sample_node['types'] = types
  
  img_node = Nokogiri::XML::Node.new 'imagepage', doc
  img_node.content = flickr_url.strip
  sample_node << img_node
  
  thumb_node = Nokogiri::XML::Node.new 'thumb', doc
  sample_node << thumb_node
  id = flickr_url.strip[/^http:\/\/www.flickr.com\/photos\/madlabuk\/[0-9]*/, 0][(38..47)]
  info = flickr.photos.getInfo(:photo_id => id)
  thumb_node.content = FlickRaw.url_q(info)
end
File.open('swabdata.xml', 'w') {|f| f.write(doc.to_xml) }