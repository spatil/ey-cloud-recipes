#
# Cookbook Name:: ey-dynamic
# Attribute:: from_json
#
# Copyright 2008, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute
#

#require 'open-uri'
#require 'json'
#
#begin
#  user_data = JSON.parse(IO.read("/etc/chef/dna.json"))
#  user_data.each do |k,v|
#    @attribute[k.to_sym] = v
#  end
#rescue Errno::ENOENT
#  "noop"
#end