require 'rubygems'
require 'em-websocket'
require 'em-jack'

EventMachine.run do
	@channel = EM::Channel.new
	EventMachine::WebSocket.start(:host => "127.0.0.1", :port => 8080) do |ws|
		ws.onopen do
			sid = @channel.subscribe { |msg| ws.send msg }
			puts "WebSocket connect (#{sid})"

			ws.onclose do
				@channel.unsubscribe sid
				puts "WebSocket closed (#{sid})"
			end

			ws.onmessage do |msg|
				@channel.push msg
			end
		end
	end
end
