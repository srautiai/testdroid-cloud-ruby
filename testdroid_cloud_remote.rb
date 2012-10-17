#!/usr/bin/ruby

require 'rubygems'
require 'stomp'

class TestdroidCloudRemote
	def initialize(username, password, url, port)  
		# Instance variables  
		@username = username  
		@password = password  
		@url = url
		@port = port
		
	end  
	def open
		puts "Connecting #{@url}:#{@port}"
		@conn = Stomp::Connection.open @username, @password, @url, @port, false 
	end
	def close
		sendCommand("END");
		sleep 5
		@conn.disconnect
	end
	def waitForConnection(queueName)
	    puts "Subscribe message from  #{queueName}"
		@conn.subscribe('/queue/'+queueName, { :ack =>"auto" } ) 
		
		while true 
			msg = @conn.receive
			puts "Receive message[#{msg.body}] from  #{queueName}\n"
			if msg.body =~ /^DEVICE_CONNECTED\s\w*/
				
				@deviceConnected = true
				match1 = msg.body.match /^DEVICE_CONNECTED\s(\w*)/
				@deviceId = match1[1]
				puts "device connected #{match1[1]}"
				@cmdDestination = msg.headers["reply-to"]
				return
			end 
		end
	end  
  
	def display  
		puts "Device(#{@deviceId}) is connected: #{@deviceConnected} reply queue: #{@cmdDestination} "  
	end  
	def touch(x,y) 
		return if !checkConn
		sendCommand("TOUCH #{x}, #{y}");
	end
	def drag(startx,starty,endx,endy,steps = 10, duration=500) 
		return if !checkConn
		sendCommand("DRAG #{startx}, #{starty}, #{endx}, #{endy}, #{steps}, #{duration}");
	end
	def reboot
		return if !checkConn
		sendCommand("REBOOT");
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
		return true
	end
	def sendCommand(monkeyCommand)
		@conn.publish @cmdDestination, monkeyCommand ,{'persistent'=>'false', 'amq-msg-type'=>'text'}
	end
end  


remote = TestdroidCloudRemote.new('','', 'localhost', 61613)
remote.open
remote.waitForConnection('DEVICEID.MONKEY.REMOTE')
remote.display
remote.touch(22,34)
sleep 5
remote.drag(22,134, 323,133)
sleep 5
remote.drag(240,134, 1,134, 9, 200)
#remote.reboot
remote.close

#puts "Done"
#Start sending commands
#STDIN.each_line { |line| 
#	puts "Publish:"+line
#	command = line.strip
#	remote.sendCommand( command )
#	if command =~ /^END\w*/
#		break
#	end
#}
#remote.close
puts "End"
