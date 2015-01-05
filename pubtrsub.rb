#!/usr/bin/env ruby
# encoding: utf-8

#
# Copyright (c) 2015 Toshinao Ishii <padoauk@gmail.com> All Rights Reserved.
#

require 'lib/pts_common'
require 'lib/server_connector'
require 'lib/client_connector'
require 'lib/pts_broker'
require 'lib/dup_translator'

#
# an example of configuring ServerConnector, ClientConnector and PtsBroker.
#

#
# server to server bi-directional
#
def network04(broker)
  sconf = Hash.new
  sconf[6400] = ['localhost']
  sconf[6401] = ['giocoso']
  sc = ServerConnector.new sconf
  broker.set_server_connector sc

  sc.start

  broker.port_map(
      PortDesc.new(:remote, sconf[6400][0], 6400),
      PortDesc.new(:remote, sconf[6401][0], 6401)
  )
  broker.port_map(
      PortDesc.new(:remote, sconf[6401][0], 6401),
      PortDesc.new(:remote, sconf[6400][0], 6400)
  )
end

#
# client to client bi-directional
#
def network03(broker)
  cconf = Hash.new
  cconf[6500] = []
  cconf[6501] = []
  cc = ClientConnector.new cconf
  cc.start

  broker.port_map(
      PortDesc.new(:local,'', 6500),
      PortDesc.new(:local,'', 6501)
  )
  broker.port_map(
      PortDesc.new(:local,'', 6501),
      PortDesc.new(:local,'', 6500)
  )

  broker.set_client_connector cc

end

#
# bi-directional between client and server
#
def network02(broker)
  sconf = Hash.new
  sconf[6400] = ['localhost']
  sc = ServerConnector.new sconf
  sc.start

  cconf = Hash.new
  cconf[6500] = []
  cc = ClientConnector.new cconf
  cc.start


  broker.port_map(
      PortDesc.new(:remote, sconf[6400][0], 6400),
      PortDesc.new(:local,  '', 6500)
  )
  broker.port_map(
      PortDesc.new(:local,  '', 6500),
      PortDesc.new(:remote, sconf[6400][0], 6400)
  )

  broker.set_server_connector sc
  broker.set_client_connector cc
end

#
# multiple connections all from server to client
#
def network01(broker)
  sconf = Hash.new
  sconf[6400] = ['localhost', 'giocoso']
  sconf[6401] = ['192.168.64.1', 'giocoso']
  sconf[6402] = ['127.0.0.1', 'giocoso']

  sc = ServerConnector.new sconf
  sc.start

  cconf = Hash.new
  cconf[6500] = []
  cconf[6501] = []
  cconf[6502] = []
  cconf[6503] = []
  cconf[6504] = []
  cconf[6505] = []

  cc = ClientConnector.new cconf
  cc.start

  #
  broker.port_map(
      PortDesc.new(:remote, sconf[6400][0], 6400),
      PortDesc.new(:local, '', 6500),
      DupTranslator.new
  )
  #
  broker.port_map(
      PortDesc.new(:remote, sconf[6401][0], 6401),
      PortDesc.new(:local, '', 6501)
  )
  #
  broker.port_map(
      PortDesc.new(:remote, sconf[6402][0], 6402),
      PortDesc.new(:local, '', 6502)
  )

  #
  broker.port_map(
      PortDesc.new(:remote, sconf[6400][1], 6400),
      PortDesc.new(:local, '', 6503)
  )
  #
  broker.port_map(
      PortDesc.new(:remote, sconf[6401][1], 6401),
      PortDesc.new(:local, '', 6504)
  )
  #
  broker.port_map(
      PortDesc.new(:remote, sconf[6402][1], 6402),
      PortDesc.new(:local, '', 6505)
  )
  #
  broker.port_map(
      PortDesc.new(:remote, sconf[6401][1], 6401),
      PortDesc.new(:remoet, sconf[6401][0], 6401)
  )

  broker.set_server_connector sc
  broker.set_client_connector cc

end

if __FILE__ == $0

  broker = PtsBroker.new
  #network01(broker)
  #network02(broker)
  #network03(broker)
  network04(broker)

  broker.start

  loop {
    sleep 3600
  }

end