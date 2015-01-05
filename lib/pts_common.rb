# encoding: utf-8

#
# Copyright (c) 2015 Toshinao Ishii <padoauk@gmail.com> All Rights Reserved.
#

require 'lib/padoauk'

class HostPortSocket
  attr_accessor :host, :port, :socket

  def initialize(h=nil, p=nil, s=nil)
    @host = (h == nil) ? h : h.to_s
    @port = (p == nil) ? p : p.to_i
    @socket = s
  end
end

class ConnectionHolder

  #
  # conf[port_no] = [host1, host2, ...]
  #
  def initialize(conf)
    # array of HostPortSocket
    ## Since configuration is static (pre-defined before run), specified string of hostnames
    ## are kept without change. They are not converted to IP addresses.
    @connect_conf = Array.new
    if conf && conf.kind_of?(Hash)
      conf.each do |port_no, hosts|
        if 0 == hosts.length
          @connect_conf.push(HostPortSocket.new("", port_no.to_i))
        else
          hosts.each do |host|
            @connect_conf.push(HostPortSocket.new(host.to_s, port_no.to_i))
          end
        end
      end
    end

    # Array of sockets, which is passed to IO.select()
    @sockets = Array.new

    @observers = Array.new

    @mutex = Mutex.new
  end

  def connected_sockets
    return @sockets
  end

  #
  # The way to establish socket is quite different in server and client.
  # It is found, on the other hand, that large part of disconnecting procedure is same.
  #
  # `sockets` may not be under management of the instance.
  # returns ture or false depending on close of socket occurs or not
  #
  def disconnect( socket )
    result = false
    l = @sockets.length
    @mutex.synchronize {
      @sockets.delete_if {|s| s == socket }
      @connect_conf.each do |c|
        c.socket = nil if socket == c.socket
      end
    }
    if @sockets.length != l
      _emit_event :disconnect # to let them know the modification
      result = true
      PadoaukLog.info "closed #{socket.peeraddr.to_s}", self
      socket.close
    end

    return result
  end

  def set_observer( obs )
    flag = false
    @observers.each { |o| flag = true if obs == o }
    @observers.push(obs) unless flag
  end

  def remove_observer( obs )
    @observers.delete_if { |o| o == obs }
  end

  private

  def _emit_event( event_type )
    @observers.each { |o| o.event(event_type, self) }
  end

end

