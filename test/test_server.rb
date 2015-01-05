#!/usr/bin/env ruby
# encoding: utf-8

require 'socket'

#
# 複数のTCPServerを、IO.selectで待ち受け、acceptする
#

if __FILE__ == $0

  ports = Hash.new
  ports[6400] = nil
  ports[6401] = nil
  ports[6402] = nil

  clients = Array.new

  rand = Random.new(Time.now.to_i)

  read_arr = Array.new
  ports.each_key do |port_no|
    begin
      server = TCPServer.open(port_no)
      ports[port_no] = server
      read_arr.push(server)
    rescue => e
      STDERR.puts "cannot open server port #{port_no}"
    end
  end

  # client accepting thread
  t0 = Thread.new do
    loop {
      ready = IO.select(read_arr)
      ready[0].each do |socket|
        client = socket.accept
        clients.push(client)
        puts "connection on #{client.addr.to_s} from #{client.peeraddr.to_s}"
      end
    }
  end
  t0.run

  # thread that close randomly
=begin
  t1 = Thread.new do
    loop {
      if rand(1.0) < 0.5
        l = clients.length
        if 0 < l
          tgt = rand(l.to_f).to_i
          s = clients.delete_at(tgt)
          puts "disconnect #{s.peeraddr.to_s} on #{s.addr.to_s}"
          s.close
        end
      end
      sleep 30 + rand(10)
    }
  end
  t1.run
=end
  t2 = Thread.new do
    loop {
      name = `hostname`
      clients.each_index do |i|
        c = clients[i]
        begin
          c.write "#{Time.now.to_s} #{name}"
          c.flush
        rescue => e
          #puts "connection #{c.peeraddr.to_s} closed" # this line works
          c.close
          clients[i] = nil
        end
      end
      clients.delete_if {|e| e == nil}
      sleep 10 + rand(5)
    }
  end
  t2.run

  t3 = Thread.new do
    begin
      loop {
        if 0 == clients.length
          sleep 5
          next
        end
        ready = IO.select(clients)
        ready[0].each do |socket|
          msg = socket.recv(4096)
          puts "#{socket.addr.to_s}> #{msg}"
        end
      }
    ensure
      puts "receiving thread terminated"
    end
  end
  t3.run

  # never comes here
  t0.join
#  t1.join
  t2.join
  t3.join
end
