#
# Cookbook Name:: ec2
# Recipe:: default
#
# Copyright 2008, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute
#

if (`grep /data /etc/fstab` == "")
  Chef::Log.info("EBS device being configured")
  
  ey_cloud_report "/data EBS" do
    message 'processing /data EBS'
  end
  
  while 1
    if File.exists?("/dev/sdz1")
        directory "/data" do
          owner 'root'
          group 'root'
          mode 0755
        end
        
        bash "format-data-ebs" do
          code "mkfs.ext3 -j -F /dev/sdz1"
          not_if "e2label /dev/sdz1"
        end
        
        bash "mount-data-ebs" do
          code "mount -t ext3 /dev/sdz1 /data"
        end
      
        bash "grow-data-ebs" do
          code "resize2fs /dev/sdz1"
        end
        
        bash "add-data-to-fstab" do
          code "echo '/dev/sdz1 /data ext3 noatime 0 0' >> /etc/fstab"
          not_if "grep /data /etc/fstab"
        end
      
      break
    end
    Chef::Log.info("EBS device /dev/sdz1 not available yet...")
    sleep 5
  end
end
