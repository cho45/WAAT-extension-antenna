#!/usr/bin/env ruby
# coding: utf-8
require 'rubygems'
require 'bundler'
Bundler.require

require 'websocket-client-simple'
require 'json'

require "i2c"

ws = WebSocket::Client::Simple.connect 'ws://localhost:51234'

avr = I2CDevice.new(address: 0x65)
antenna_map = [
	"UHV-6",
	"MicroVert",
	"NC",
	"NC"
]

prev = nil
loop do
	begin
		ant = avr.i2cget(0x00).unpack("c")[0].to_i
		name = antenna_map[ant]
		if ant != prev
			p "changed %d %s" % [ant, name]
			ws.send JSON.generate({"method"=>"broadcast", "id" => "0", "params" => { "result" => { "antenna.id" => ant, "antenna.name" => name } } })
			prev = ant
		end
		sleep 0.5
	rescue => e
		p e
		sleep 1
	end
end

