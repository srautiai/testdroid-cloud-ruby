#!/usr/bin/ruby

require 'rubygems'
require 'stomp'
require 'json'

class TestdroidCloudRemote
	def initialize(username, password, url, port)  
		# Instance variables  
		@username = username  
		@password = password  
		@url = url
		@port = port
		
	end  
	#Open connection to remote server
	def open
		puts "Connecting #{@url}:#{@port}"
		@remoteClient = Stomp::Client.new(@username, @password, @url, @port, true)
	end
	#End session - free to device for other use
	def close
		send_command("END");
		sleep 5
		@remoteClient.close
	end
	# wait until device is available 
	def wait_for_connection(build_id, device_id, time_out=0)
		puts "Waiting for device #{device_id}"
		queue_name = "/queue/#{build_id}.REMOTE.#{device_id}"
		@remoteClient.subscribe(queue_name, { :ack =>"auto" }, &method(:receiveMsg))
		begin 
			Timeout::timeout(time_out) do
				while @cmdDestination.nil?  do
				sleep 0.3 
				end
			end
			rescue Timeout::Error
			$stderr.puts "Timeout when waiting device to connect" 
			return nil
		end
	end  
	#Show device connection
	def display  
		puts "Device(#{@deviceId}) is connected: #{@deviceConnected} reply queue: #{@cmdDestination} "  
	end  
	#Touch device screen on coordinates
	def touch(x,y) 
		return if !checkConn
		send_command("TOUCH #{x}, #{y}");
	end
	#Drag from position to other with steps and duration
	def drag(startx,starty,endx,endy,steps = 10, duration=500) 
		return if !checkConn
		send_command("DRAG #{startx}, #{starty}, #{endx}, #{endy}, #{steps}, #{duration}");
	end
	#Reboot device
	def reboot
		return if !checkConn
		send_command("REBOOT");
	end
	#am  start -n command: am start -n com.bitbar.testdroid/.BitbarSampleApplicationActivity
	def start_activity(activity)
		return if !checkConn
		send_command("START_ACTIVITY #{activity}");
	end
	#Get device properties from device
	def device_properties()
		return if !checkConn
		send_command("REQUEST_PROPERTIES")
		return get_response
	end
	#Take screenshot and store into file system
	def take_screenshot(filename = "screenshot1.png")
		return if !checkConn
		@screenshotFilename = filename
		send_command("SCREENSHOT")
		get_response
	end
	
	private
	def send_command(monkeyCommand)
		@remoteClient.publish(@cmdDestination, monkeyCommand ,{'persistent'=>'false', 'amq-msg-type'=>'text'})
	end
	def receiveMsg(msg)
	
		if !@cmdDestination.nil?
			if !msg.headers["content-length"].nil?
				puts "Saving binary message #{@screenshotFilename}"
				
				a_file = File.open(@screenshotFilename, "wb") 
				a_file.write(msg.body)
				a_file.close
				@response  = @screenshotFilename
				
				
				return
			end

			@response = JSON.parse( msg.body )

			return;
		end
		if msg.body =~ /^DEVICE_CONNECTED\s\w*/
					
			@deviceConnected = true
			match1 = msg.body.match /^DEVICE_CONNECTED\s(\w*)/
			@deviceId = match1[1]
			puts "device connected #{match1[1]}"
			@cmdDestination = msg.headers["reply-to"]
			return
		end 
	end
	
	def checkConn
		if @deviceId.nil? 
			$stderr.puts "Not connected to device" 
			return false
		end
		if @cmdDestination.nil? 
			$stderr.puts "Not connected to device - no reply destination" 
			return false
		end
		if @remoteClient.closed? 
			$stderr.puts "Client is not connected" 
			return false
		end
		return true
	end
	
	
	def get_response
		begin
		# Don't take longer than 20 seconds to retrieve content
		Timeout::timeout(20) do
			while @response.nil?  do
				sleep 0.3 
			end
		end
		rescue Timeout::Error
			$stderr.puts "Timeout when receiving response" 
			return nil
		end
		
		lastResponse =  @response.clone
		@response = nil
		return lastResponse
	end
end  

if __FILE__ == $0

remote = TestdroidCloudRemote.new('','', 'localhost', 61613)
remote.open
remote.wait_for_connection('12345','016B732C1900701A')
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
remote.drag(240,134, 1,134, 9, 200)
remote.take_screenshot("screenshot12.png")
remote.close
puts "End"
end
