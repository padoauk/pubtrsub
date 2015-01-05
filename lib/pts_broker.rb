# encoding: utf-8

#
# Copyright (c) 2015 Toshinao Ishii <padoauk@gmail.com> All Rights Reserved.
#

require 'socket'

require 'lib/server_connector'
require 'lib/client_connector'
require 'lib/translator'

class PortDesc
  attr_accessor :type, :host, :port
  def initialize( sym=nil, host=nil, num=nil )
    @type = sym
    # :local  is server (waiting) port of its own process
    # :remote is server (waiting) port of other (include remote) processes
    if @type != :remote && @type != :local
      @type = nil
      PadoaukLog.warn "PortDesc type must be either :remote or :local", self
    end
    # hostname is kept by IP address
    @host = (@type == :local) ? "" : Socket.getaddrinfo(host,nil)[0][3].to_s
    @port = (num != nil) ? num.to_i : -1
  end

  def dup
    return PortDesc.new(@type, @host, @port)
  end

  def to_s
    return "#{@type}|#{@host}|#{@port.to_s}"
  end
end

#
# Broker of Publish - Translate - Subscirbe
#
class PtsBroker

  def initialize
    # Array of sockets
    ## server sockets provided by ServerConnector
    @server_sockets = nil
    ## client sockets provided by ClientConnector
    @client_sockets = nil
    ## all (server + client) sockets
    @socket_arr = Array.new

    # map from socket to PortDesc
    @socket2desc = Hash.new
    # map from PortDesc to Array of sockets
    @desc2socket = Hash.new

    # map from source PortDesc to destination PortDesc
    @src_desc2dest_desc = Hash.new

    # translators
    ## translator from portDescA to portDescB is kept in @translator[_src2dst_key(portDescA, portDescB)]
    @translators = Hash.new
    # thread of doing data transfer
    @thread = nil
    #
    @mutex = Mutex.new
  end

  #
  # add a map from source description to array of destination description.
  # in run time, descriptions are associated with sockets
  #
  def port_map(src_port_desc, dst_port_desc, translator=nil)
    unless src_port_desc && dst_port_desc && src_port_desc.kind_of?(PortDesc) && dst_port_desc.kind_of?(PortDesc)
      PadoaukLog.warn "invalid parameter", self
      return
    end

    sdesc = src_port_desc.dup
    ddesc = dst_port_desc.dup

    key = sdesc.to_s
    @src_desc2dest_desc[key] = Array.new unless @src_desc2dest_desc.has_key?(key)
    @src_desc2dest_desc[key].push(ddesc)

    set_translator(sdesc, ddesc, translator)
  end

  def set_server_connector(sc)
    @server_connector = sc if sc && sc.kind_of?(ServerConnector)
    sc.set_observer self
    @server_sockets = @server_connector.connected_sockets
    _update_sockets

    return
  end

  def set_client_connector(cc)
    @client_connector = cc if cc && cc.kind_of?(ClientConnector)
    cc.set_observer self
    @client_sockets = @client_connector.connected_sockets
    _update_sockets

    return
  end

  def set_translator(src_port_desc, dst_port_desc, tr=nil)
    unless src_port_desc && dst_port_desc && src_port_desc.kind_of?(PortDesc) && dst_port_desc.kind_of?(PortDesc)
      PadoaukLog.warn "set_translator port description is invalid", self
      return
    end
    unless  tr && tr.kind_of?(Translator)
      PadoaukLog.warn "default translator for src: #{src_port_desc.to_s}, dst: #{dst_port_desc.to_s} ", self
      tr = Translator.new
    end
    @translators[_src2dst_key(src_port_desc, dst_port_desc)] = tr
  end

  def start
    _listen_server
  end

  def stop
    if @thread
      @thread.exit
      @thread = nil
    end
  end

  def wait
    @thread.join if @thread
  end

  def event( event_type, obs )
    _update_sockets
  end


  private

  #
  # non-blocking. the listening job is done in a new Thread.
  #
  def _listen_server
    return false if @thread

    @thread = Thread.new do
      begin
        loop {
          begin
            _listen_server_core
          rescue
          end
        }
      ensure
        PadoaukLog.error 'thread of handling io is terminated', self
      end
    end

    return true
  end

  def _listen_server_core
    if 0 == @socket_arr.length
      sleep 5
      return
    end
    ready = IO.select(@socket_arr, [], [], 5)
    return if ready == nil # timeout

    ready[0].each do |socket|
      rmsg = socket.recv(4096)
      sdesc = @socket2desc[socket]
      dst_arr = @src_desc2dest_desc[sdesc.to_s]
      if 0 == rmsg.length
        _disconnect(socket)
        return
      end
      next if dst_arr == nil
      dst_arr.each do |ddesc|
        translator = @translators[_src2dst_key(sdesc, ddesc)]
        translator.translate rmsg
        translator.get_segments.each do |seg|
          if @desc2socket.has_key?(ddesc.to_s)
            @desc2socket[ddesc.to_s].each do |s|
              begin
                if s
                  s.write seg
                  s.flush
                end
              rescue => e
                _disconnect(s)
              end
            end
          end
        end
      end
    end
  end

  #
  # collect all sockets and keep them in @socket_arr
  # update map from socket instance to PortDesc
  #
  def _update_sockets
    @mutex.synchronize {
      @socket_arr.clear
      @socket2desc.clear
      @desc2socket.clear
      if @server_sockets
        @server_sockets.each do |s|
          @socket_arr.push(s)
          d = PortDesc.new(:remote, s.peeraddr[3], s.peeraddr[1])
          @socket2desc[s] = d
          key = d.to_s
          @desc2socket[key] = Array.new unless @desc2socket.has_key?(key)
          @desc2socket[key].push(s)
        end
      end
      if @client_sockets
        @client_sockets.each do |s|
          @socket_arr.push(s)
          d = PortDesc.new(:local, s.addr[3], s.addr[1])
          @socket2desc[s] = d
          key = d.to_s
          @desc2socket[key] = Array.new unless @desc2socket.has_key?(key)
          @desc2socket[key].push(s)
        end
      end
    }
  end

  def _disconnect(socket)
    key = @socket2desc[socket].to_s
    @desc2socket[key].delete_if{ |s| s == socket }
    @server_connector.disconnect socket
    @client_connector.disconnect socket

  end

  def _src2dst_key(src, dst)
    return "#{src.to_s} -> #{dst.to_s}"
  end
end