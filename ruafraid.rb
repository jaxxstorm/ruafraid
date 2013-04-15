#!/usr/bin/env ruby

require 'net/http'
require 'rexml/document'
require 'pp'

# Put your FreeDNS URL here
url = ''
ip_url = 'http://icanhazip.com'


if url.empty?
  puts "You haven't set an API URL. Try again"
  exit 1
end

  # get the required data
response = Net::HTTP.get_response(URI.parse(url))
if response.code.chomp != "200"
  puts "Bad result from freedns.afraid.org"
  puts "Please check your API url"
  exit 2
end

error_messages = /ERROR: Could not authenticate./
if response.body =~ error_messages
  puts "There was an error trying to authenticate"
  puts "Have you changed your password?"
  puts "Please check your FreeDNS API url"
  exit 3
end


xml_data = response.body

# this needs to resolve JUST an IP
curr_ip = Net::HTTP.get_response(URI.parse(ip_url)).body

# extract event information
doc = REXML::Document.new(xml_data)

# initialize a hash for the hosts
hosts = {}
# loop through each host and get the XML elements

doc.elements.each('xml/item') do |i|
    si1, others = nil, {}
    i.elements.each do |e|
        if e.name == 'host'
            si1 = e.text
        else
            others[e.name] = e.text
        end
    end
    hosts[si1] = [] if !hosts[si1]
    hosts[si1] << others
end

# What we end up with is a hash of arrays
# so first we need to loop through the hash keys
# and then lopp through the array and compare the IP address to the current IP
hosts.each_pair do |key,value|
  hosts[key].each do |x|
    if x["address"] == curr_ip.chomp
      puts "#{key} does not need updating"    
    else 
      # we need to download the URL here, it's referenced with x["url"]
      puts "#{key} needs updating"
      update_host = Net::HTTP.get_response(URI.parse(x["url"])).body
      puts "#{key} has been updated to #{curr_ip}"
    end
  end
end







