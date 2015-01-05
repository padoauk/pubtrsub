# encoding: utf-8

#
# Copyright (c) 2015 Toshinao Ishii <padoauk@gmail.com> All Rights Reserved.
#

require 'lib/padoauk'

#
# translator base class
#
class Translator
  #include Java

  def initialize
    @mutex = Mutex.new
    #@buffer = java.nio.ByteBuffer.allocate(8192)
    @buffer = String.new
  end

  # `stream` should be an instance of String or Array
  def translate(stream)
    if stream.kind_of?(Array)
      @buffer = @buffer + stream.pack("C*")
    elsif stream.kind_of?(String)
      @buffer = @buffer + stream
    else
      PadoaukLog.warn "translate cannot process #{stream.class}", self
    end
  end

  #
  # In derived classes, make_segments should be overwritten.
  #
  # In make_segments, content of @buffer should be segmented and all the extracted segments
  # should be packed in an Array intance and returned.
  # In addition, processed content must be removed from @buffer.
  #
  def make_segments
    # just copy buffer in this base class
    arr = Array.new
    arr.push(@buffer)
    @buffer = String.new
    return arr
  end

  def get_segments
    return make_segments
  end

end

#
# add method of to_jb
#
class Fixnum
  # to Java byte
  # takes a Ruby Fixnum and returns the value as signed byte range -128..128 (Java byte).
  # rasies RangeError
  def to_jb
    raise RangeError,"too big for Java byte: #{self}" if (self < -128 || self > 255)
    if self > 127 then
      return self - 256
    else
      return self
    end
  end
end


class String
  # ex)
  #   buffer = java.nio.ByteBuffer.allocate(1024)
  #   buffer.put "Hello World !".unpack_to_jb
  # unpack_to_jb is not necessary for String of ASCII chars.
  # unpack_to_jb is necessary, in general, in the following case
  #   str = socket.recv(1024)
  #   buffer.put str.unpack_to_jb
  def unpack_to_jb
    self.unpack("C*").map{|e| e.to_i.to_jb}.to_java(:byte)
  end
end

class Array
  # ex)
  #   buffer = java.nio.ByteBuffer.allocate(1024)
  #   buffer.put [1,2,128,256].to_jb
  # or
  #   str = socket.recv(1024)
  #   buffer.put str.unpack("C*").to_jb
  def to_jb
    return self.map {|e| e.to_i.to_jb }.to_java(:byte)
  end
end
