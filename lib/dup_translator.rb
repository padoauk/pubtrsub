# encoding: utf-8

#
# Copyright (c) 2015 Toshinao Ishii <padoauk@gmail.com> All Rights Reserved.
#

require 'lib/translator'

#
# an example of translator
#
class DupTranslator < Translator

  def make_segments
    str = "#{@buffer}\t#{@buffer}\n"
    @buffer = String.new
    return [str]
  end

end