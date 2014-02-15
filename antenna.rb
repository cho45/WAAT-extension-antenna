#!/usr/bin/env ruby
# coding: utf-8
require 'rubygems'
require 'bundler'
Bundler.require

require 'websocket-client-simple'
require 'json'


class I2CDevice
	# ioctl command
	# Ref. https://www.kernel.org/pub/linux/kernel/people/marcelo/linux-2.4/include/linux/i2c.h
	I2C_RETRIES     = 0x0701
	I2C_TIMEOUT     = 0x0702
	I2C_SLAVE       = 0x0703
	I2C_SLAVE_FORCE = 0x0706
	I2C_TENBIT      = 0x0704
	I2C_FUNCS       = 0x0705
	I2C_RDWR        = 0x0707
	I2C_SMBUS       = 0x0720
	I2C_UDELAY      = 0x0705
	I2C_MDELAY      = 0x0706

	attr_accessor :address

	def initialize(address)
		@address = address
	end

	def i2cget(address, length=1)
		i2c = File.open("/dev/i2c-1", "r+")
		i2c.ioctl(I2C_SLAVE, @address)
		i2c.write(address.chr)
		ret = i2c.read(length)
		i2c.close
		ret
	end

	def i2cset(*data)
		i2c = File.open("/dev/i2c-1", "r+")
		i2c.ioctl(I2C_SLAVE, @address)
		i2c.write(data.pack("C*"))
		i2c.close
	end
end

ws = WebSocket::Client::Simple.connect 'ws://localhost:51234'

avr = I2CDevice.new(0x65)
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

