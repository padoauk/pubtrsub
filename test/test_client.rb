#!/usr/bin/env ruby
# encoding: utf-8

require 'socket'

if __FILE__ == $0
  ptshosts = ['localhost', '127.0.0.1', '192.168.64.1', 'ijexa.divagari.net']
  ptsports = [6500, 6501, 6502, 6503, 6504, 6505]

  max_connection = 32
  sockets = Array.new
  mutex = Mutex.new
  rand = Random.new(Time.now.to_i)

  begin
    s = TCPSocket.open(ptshosts[0], ptsports[0])
      sockets.push(s)
  rescue => e

  end

  t0 = Thread.new do
    begin
      loop {
        close_list = Array.new
        if 0 == sockets.length
          sleep 30
        else
          ready = IO.select(sockets)
          ready[0].each do |so|
            msg = so.recv(4096)
            if msg && 0 == msg.length
              puts "#{Time.now.to_s} woops !"
              sockets.delete_if{ |s| s == so }
              begin
                so.close
              rescue => e
              end
            else
              puts "#{so.peeraddr[2]}:#{so.peeraddr[1]}> #{msg}"
            end
            close_list.push(so) if rand(20.0) < 1.0
          end
        end

        close_list.each do |s|
          sockets.delete_if {|t| t == s}
        end
        close_list.each do |s|
          puts "closed #{s.peeraddr.to_s}"
          s.close
        end
      }
    ensure
      puts "message receiving thread terminated"
    end
  end
  t0.run

  t1 = Thread.new do
    begin
      loop {
        if sockets.length < max_connection
          h = ptshosts[rand(ptshosts.length)]
          p = ptsports[rand(ptsports.length)]
          begin
            s = TCPSocket.open(h,p)
            puts "connected to #{s.peeraddr.to_s}"
            mutex.synchronize {
              sockets.push(s)
            }
          rescue => e
          end
        end
        sleep 10 + rand(5)
      }
    ensure
      puts "connecting thread terminated"
    end
  end
  t1.run

  sleep 5
=begin
  t2 = Thread.new do
    begin
      loop{
        if 0 == sockets.length
          sleep 30
          next
        end
        begin
          tgt = rand(sockets.length.to_f).to_i
          s = sockets[tgt]
          mutex.synchronize {
            puts "closed #{s.peeraddr.to_s}"
            s.close
          }
        rescue
        end
        sleep 15 + rand(5)
      }
    ensure
      puts "closing thread terminated"
    end
  end
  t2.run
=end

  loop {
    sleep 3600
  }
end