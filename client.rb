#!/usr/bin/env ruby
$:.unshift File.expand_path '../lib', File.dirname(__FILE__)
require 'rubygems'
require 'hue'
require 'websocket-client-simple'
require 'sonos'

puts Time.now.to_s
ws = WebSocket::Client::Simple.connect 'wss://kerst-2016-server.herokuapp.com:443'

ws.on :message do |msg|
  puts ">> #{msg.data} " + Time.now.to_s
  if msg.to_s == 'Driving home for Christmas'
    start_christmas('x-sonos-spotify:spotify%3atrack%3a66mB55sZuDHlXt3vAcVkXf?sid=9&amp;flags=0')
  elsif msg.to_s == 'All I want for Christmas is you'
    start_christmas('x-sonos-spotify:spotify%3atrack%3a5KdPyhcsQ5PvkvPBq6lLti?sid=9&amp;flags=0')
  elsif msg.to_s == 'Last Christmas'
    start_christmas('x-sonos-spotify:spotify%3atrack%3a0QPYn15U8IQHKcH2LDfrek?sid=9&amp;flags=0')
  elsif msg.to_s == "It's beginning to look a lot like Christmas"
    start_christmas('x-sonos-spotify:spotify%3atrack%3a5a1iz510sv2W9Dt1MvFd5R?sid=9&amp;flags=0')
  elsif msg.to_s == 'Jingle bell rock'
    start_christmas('x-sonos-spotify:spotify%3atrack%3a2wCPMWR3y4xclijuCcLJv7?sid=9&amp;flags=0')
  elsif msg.to_s == 'Rudolph the red-nosed reindeer'
    start_christmas('x-sonos-spotify:spotify%3atrack%3a4o8Zh55Xh9sBPJCM1g0Lf7?sid=9&amp;flags=0')
  end

  stop if msg.to_s == 'Stop'

  start_christmas('x-sonos-spotify:spotify%3atrack%3a66mB55sZuDHlXt3vAcVkXf?sid=9&flags=0') if msg.to_s == 'christmas'

  #ws.close if Time.now > @time
end

ws.on :open do
  puts "-- websocket open (#{ws.url})"
  ws.send 'ping'
  #@time = Time.now + 1800
end

ws.on :error do |e|
  puts "-- error (#{e.inspect})" + "\n"
  puts Time.now.to_s
  ws.connect('ws://kerst-2016-server.herokuapp.com')
end

ws.on :close do
  ws.connect('ws://kerst-2016-server.herokuapp.com')
end

def start_christmas(song)
  initialize_variables
  @speaker.volume = 5
  @time = Time.now
  play(song)
  @speaker.play
  cycle
end

def play(song)
  song.to_s.slice! '?sid=9&amp;flags=0'
  song.to_s.slice! '?sid=9&flags=0'
  if @speaker.now_playing[:uri] == song + '?sid=9&flags=0'
    @speaker.play
  else
    @speaker.play song + '?sid=9&amp;flags=0'
  end
end

def stop
  initialize_variables
  @speaker.pause
end

def cycle
  Thread.new do
    while @speaker.is_playing?
      sleep 2
      turn_red
      sleep 2
      turn_green
    end
    sleep 1
    @lights.each do |light|
      light.set_state(xy: [0.4387, 0.4047])
    end
  end
end

def turn_green
  @light1.set_state(xy: [0.05, 0.85])
  @light3.set_state(xy: [0.7, 0.3])
  @light2.set_state(xy: [0.05, 0.85])
end

def turn_red
  @light1.set_state(xy: [0.7, 0.3])
  @light3.set_state(xy: [0.05, 0.85])
  @light2.set_state(xy: [0.7, 0.3])
end

def initialize_variables
  @client = Hue::Client.new
  @lights = @client.lights
  @light1 = @client.lights.fetch(0)
  @light2 = @client.lights.fetch(1)
  @light3 = @client.lights.fetch(2)

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

