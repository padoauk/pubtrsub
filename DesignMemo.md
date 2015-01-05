Pubtrsub features
===============================================

- configurable
- possible to tramsmit steram
  - from server port to client port
  - from client port to server port
  - from server port to server port
  - from client port to client port
- bi-directional transmission
- reconnectable
- plug-in translations of streams

classes
===============================================

class ConnectionHolder
-----------------------------------------------
Responsibilities of this class are:

- to keep static (defined before running) configuration of connection a set of configuration is kept in an instance of class HostPortSocket
- to keep connected sockets
  1. HostPortSocket instance keeps an active socket as well as static conf
  2. Making connection is not the responsibility of this base class since the way how to connect is different between types.
  3. Derived classes should do this job.
- to disconnect specified sockets
  1. How to disconnect has common procedures among client type and server type sockets.
- tell observers when something changed in the keeping sockets
  1. This base class tells only in case of disconnect.
  2. Other events should be emitted by derived classes.


class ServerConnector
-----------------------------------------------
A derived class of ConnectionHolder. Responsibilities of this class are:

- start and keep trying to connect to external server
- restart and keep trying to connect if an socket to external server is disconnected
- emit connection event to observers
- the established socket is kept by using capability of ConnectionHolder


class ClientConnector
-----------------------------------------------
A derived class of ConnectionHolder. Responsibilities of this class are

- open waiting ports for clients to connect to
- accept connection which come to one of the waiting ports
- emit connection event to observers
- the established socket is kept by using capability of ConnectionHolder

Connections from clients comes unexpectedly. To respond all of them, IO.select() is invoked repeatedly in a dedicated thread.


class Translator
-----------------------------------------------
Translator is a just-copy-translator as well as base class of translators. Derived classes should overwrite
the method of make_segments which should return translated segments of buffered stream.

Responsibilities of this class are:

- buffers input stream
- segments buffered steram


class PtsBroker
-----------------------------------------------
PtsBroker object has a ServerConnector object and a ClientConnector object and realizes network of inputs and outputs.
Streams from input sockets are transmitted to to output sockets. PtsBroker assumes that configuration of network is defined
with hostname and port number of servers which include its own process. For example, an instance of PtsBroker transmits
stream from hostA's port 6000 to clients which have connection to its own port 6001. The same instance can transmits
stream from hostB's port 6002 to hostC's port 6003.

### termilonogy
Network between sockets managed by PtsBroker instance is configured (pre-defined) with hostnames and servers' port number.
**Port_desc** is information which consists hostname, port number and discrimination of remote or local. Local does not
mean the ports of localhost. It means port of its own process. The hostname of 'local' port is represented by "" (nil).


To realize this, the following information should be maintained.

- (a) map from socket to port_desc
- (b) map from source port_desc to list of destination port_desc.
- (c) map from port_desc to sockets

Notice that more than two sockets from clients may have (exactly) identical port_desc. Therefore, value of map (c) is
array of sockets.

When a chunk of stream arrives, the following should happen

1. find source port_desc by using (a)
2. find destination port_desc (can be more than one) by using (b)
3. find destination sockets by using (c)


Responsibilities of this class are:

- configure network of port_desc (hostname and port)
- associate with ServerConnector and ClientConnector (called connectors below)
- maintain network of sockets which changes dynamically depending on external processes with the help of connectors
- find termination of sockets and tell the event to connectors
- receive streams
- invoke translation of streams
- transmit translated streams


#### Copyright
Copyright (c) 2015 Toshinao Ishii <padoauk@gmail.com> All Rights Reserved.