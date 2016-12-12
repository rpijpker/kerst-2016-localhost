#!/usr/bin/env ruby
$:.unshift File.expand_path '../lib', File.dirname(__FILE__)
require 'rubygems'
require 'websocket-client-simple'
require 'hue'
require 'sonos'

puts "websocket-client-simple v#{WebSocket::Client::Simple::VERSION}"
puts Time.now.to_s

ws = WebSocket::Client::Simple.connect 'ws://kerst-2016-server.herokuapp.com'

ws.on :message do |msg|
  puts ">> #{msg.data}"
  if msg.to_s == 'Driving home for Christmas'
    start_christmas('x-sonos-spotify:spotify%3atrack%3a66mB55sZuDHlXt3vAcVkXf?sid=9&amp;flags=0')
  elsif msg.to_s == 'All I want for Christmas is you'
    start_christmas('x-sonos-spotify:spotify%3atrack%3a5KdPyhcsQ5PvkvPBq6lLti?sid=9&amp;flags=0')
  elsif msg.to_s == 'Last Christmas'
    start_christmas('x-sonos-spotify:spotify%3atrack%3a0QPYn15U8IQHKcH2LDfrek?sid=9&amp;flags=0')
  elsif msg.to_s == "It's beginning to look a lot like Christmas"
    start_christmas('x-sonos-spotify:spotify%3atrack%3a5a1iz510sv2W9Dt1MvFd5R?sid=9&amp;flags=0')
  end

  start_christmas('x-sonos-spotify:spotify%3atrack%3a66mB55sZuDHlXt3vAcVkXf?sid=9&amp;flags=0') if msg.to_s == 'christmas'
end

ws.on :open do
  puts "-- websocket open (#{ws.url})"
  ws.send 'ping'
end

ws.on :error do |e|
  puts "-- error (#{e.inspect})"
  puts Time.now.to_s
  ws.close
end

ws.on :close do
  sleep 1
  ws.connect('ws://kerst-2016-server.herokuapp.com')
end

def start_christmas(song)
  initialize_variables
  @time = Time.now
  play(song)
  @speaker.play
  cycle
end

def play(song)
  @speaker.play song
  @speaker.volume = 5
end

def stop
  @speaker.stop
end

def cycle
  color = [@light.x, @light.y]
  while @speaker.is_playing?
    sleep 2
    turn_red
    sleep 2
    turn_green

    @speaker.stop if Time.now > @time + 11
  end
  @light.set_state(xy: [color[0], color[1]])
end

def turn_green
  @light.set_state(xy: [0.05, 0.85])
end

def turn_red
  @light.set_state(xy: [0.7, 0.3])
end

def initialize_variables
  @client = Hue::Client.new
  @light = @client.lights.fetch(1)
  while @light.name != 'Hue color lamp 2'
    @client = Hue::Client.new
    @light = @client.lights.fetch(1)
  end

  @system = Sonos::System.new
  @speaker = @system.speakers.fetch(0)
  i = 0
  while @speaker.name != 'Kantine'
    i = 0 if i > 7
    @speaker = @system.speakers.fetch(i)
    i += 1
  end
end

loop do
  ws.send STDIN.gets.strip
end
