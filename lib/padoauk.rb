# encoding: utf-8

=begin
 Copyright (c) 2014 Toshinao Ishii <padoauk@gmail.com> All Rights Reserved
=end

#
# logging message utility
#
module PadoaukLog

  def info(msg, klass)
    _padoauk_log("info", msg, klass)
  end

  def warn(msg, klass)
    _padoauk_log("warn", msg, klass)
  end

  def error(msg, klass)
    _padoauk_log("error", msg, klass)
  end

  #
  # debug_levels
  #  0b0000_0000 : no debug message
  #  0b0000_0001 : value check
  #  0b0000_0100 : logic check
  #  0b0000_1000 : performance check
  #
  def debug(msg, klass, debug_level)
    if $DebuggingLevel && (debug_level & $DebuggingLevel)
      _padoauk_log("debug", msg, klass)
    end
  end

  module_function :info, :warn, :error, :debug

  private

  def self._padoauk_log(level, msg, klass)
    tm = Time.now.strftime('%Y-%m-%d %H:%M:%S.%L')
    kn = ''
    if klass == nil
      kn = ''
    elsif klass.kind_of?(String)
      kn = klass
    else
      kn = klass.class.name
    end

    puts "time: #{tm}, level: #{level}, class: #{kn}, msg: #{msg.to_s}"
  end

end