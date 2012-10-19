#!/usr/bin/ruby
require './testdroid_cloud_remote.rb'

def test_run(username,password,host,build_id, device_id)
	begin 
		remote = TestdroidCloudRemote.new(username,password, host, 61613)
		
		remote.open
		remote.wait_for_connection(build_id,device_id)
		remote.display
		dev_prop = remote.device_properties
		if dev_prop.nil? 
			remote.close
			abort "Error receiving"
			
		end
		puts "X: #{dev_prop['display.height']}"
		puts "Y: #{dev_prop['display.width']}"

		remote.touch(22,34)
		sleep 5
		
		remote.drag(22,134, 323,133)
		sleep 5
		remote.start_activity("com.bitbar.testdroid.html5/.SampleActivity")
		
		remote.drag(240,134, 1,134, 9, 200)
		sleep 5
		remote.take_screenshot("screenshot12.png")

		#remote.reboot
		remote.close
	end
end

if ARGV.length == 5 
	test_run(ARGV[0], ARGV[1],ARGV[2],ARGV[3],ARGV[4])
else
  STDOUT.puts <<-EOF
Please provide parameters

Usage:
  remote_control.rb <username> <password> <server> <build_id> <device_id>
EOF
end
