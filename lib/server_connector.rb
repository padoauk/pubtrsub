# encoding: utf-8

#
# Copyright (c) 2015 Toshinao Ishii <padoauk@gmail.com> All Rights Reserved.
#

require 'socket'
require 'thread'

require 'lib/pts_common'

#
# a "server" is a external process to which this process connects
#
# ServerConnector makes connection sockets to the configured servers and
# manages the sockets.
#
class ServerConnector < ConnectionHolder

  #
  # conf['hostname'] = port
  #
  def initialize(conf)
    super conf

    @connecting = false
  end

  # `sockets` may not be under management
  def disconnect( socket )
    flag = super socket
    _connect if flag
    return flag
  end

  # start does not wait. all is done in other threads
  def start
    _connect
    sleep 1
  end

  private

  def _connect
    return if @connecting

    @connecting = true
    t = Thread.new do
      begin
        loop {
          nb = 0
          done = true
          @connect_conf.each do |c|
            @mutex.synchronize {
              next if c.socket != nil
              begin
                s = TCPSocket.open(c.host, c.port)
                c.socket = s
                @sockets.push(c.socket)
                nb = nb + 1
                PadoaukLog.info "connected to #{c.host} on port #{c.port}", self
              rescue => e
                done = false
                PadoaukLog.info "sleep and will retry to connect to #{c.host} on port #{c.port}", self
              end
            }
          end
          _emit_event :connect if 0 < nb
          break if done
          sleep 30
        }
      ensure
        @connecting = false
      end
    end
  end

end