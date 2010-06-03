#
# Cookbook Name:: ey-dynamic
# Attribute:: from_json
#
# Copyright 2008, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute
#

# Set the owner_name to the first username
owner_name(@attribute[:users].first[:username])
owner_pass(@attribute[:users].first[:password])