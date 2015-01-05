# encoding: utf-8

#
# Copyright (c) 2015 Toshinao Ishii <padoauk@gmail.com> All Rights Reserved.
#

require 'lib/pts_common'

#
# a "client" is a process which initiates connection to this process
#
# ClientConnector waits for clients and manages accepted sockets
#
class ClientConnector < ConnectionHolder

  def initialize(conf)
    # conf['hostname'] = port_no
    # for ClientConnector, hostname has no meaning (so far)
    super conf

    @wait_servers = Array.new
  end

  def start
    _open_connection
    _wait_connection
    sleep 1
  end

  private

  #
  # open accepting sockets
  #
  def _open_connection

    if @connect_conf && @connect_conf.kind_of?(Array)
      @connect_conf.each do |hps|
        port = hps.port
        begin
          s = TCPServer.open(port)
          @wait_servers.push(s)
        rescue => e
          PadoaukLog.error "failed to open port on #{port} #{e.to_s}", self
        end
      end
    end
  end

  def _wait_connection
    t = Thread.new do
      begin
        loop {
          ready = IO.select(@wait_servers)
          nb=0
          ready[0].each do |srv|
            socket = srv.accept
            @sockets.push(socket)
            PadoaukLog.info "connected #{socket.peeraddr.to_s}", self
            nb = nb + 1
          end
          if 0 < nb
            _emit_event :connect
          end
        }
      ensure
        PadoaukLog.warn "_wait_connection stopped", self
      end
    end

    t.run
  end

end