# -*- coding: utf-8 -*-


# System Extensions
require 'rubygems'
require 'stringio'

# RSpec
$:.push('.')
require 'spec_helper'

# Custom
$:.push('lib')
require 'Logger'


# Logger is part of the Utils Module
include Utils


# Can we capture STDOUT?
module Kernel

  def capture_stdout
    out = StringIO.new
    $stdout = out
    yield
    return out
  ensure
    $stdout = STDOUT
  end

end


describe Logger do # {{{


  describe "#new" do # {{{

    before do
    end

    it "raises ArgumentError if intiantiated with nil" do
      lambda { Logger.new( nil ) }.should raise_error( ArgumentError )
    end

    it "raises ArgumentError if intiantiated with non-ostruct object" do
      lambda { Logger.new( 42 ) }.should raise_error( ArgumentError )
    end

  end # }}}


  describe "#colorize" do # {{{

    before do
      options            = OpenStruct.new
      options.colorize   = true

      @logger = Logger.new( options )
    end

    it "returns ArgumentError if we pass nil as first argument" do
      lambda { @logger.colorize( nil, "Test" ) }.should raise_error( ArgumentError )
    end

    it "returns ArgumentError if we pass nil as second argument" do
      lambda { @logger.colorize( "Gray", nil ) }.should raise_error( ArgumentError )
    end

    it "returns ArgumentError if we pass nil as first and second argument" do
      lambda { @logger.colorize( nil, nil ) }.should raise_error( ArgumentError )
    end

    it "returns a proper grey format string if we pass (\"Gray\", \"Message\")" do
      @logger.colorize( "Gray", "Message" ).should == "\e[1;30mMessage\e[0m"
    end

  end # }}}


  describe "#message" do # {{{

    before do

      options            = OpenStruct.new
      options.colorize   = true

      @logger = Logger.new( options )
    end

    it "returns ArgumentError if we pass nil as first argument" do
      lambda { @logger.message( nil, "Test" ) }.should raise_error( ArgumentError )
    end

    it "returns ArgumentError if we pass nil as second argument" do
      lambda { @logger.message( :info, nil ) }.should raise_error( ArgumentError )
    end

    it "returns ArgumentError if we pass nil as first and second argument" do
      lambda { @logger.message( nil, nil ) }.should raise_error( ArgumentError )
    end

    # This testing is a problem, how to capture STDOUT for logger class?
    # http://thinkingdigitally.com/archive/capturing-output-from-puts-in-ruby/
    # it "returns a properly BROWN formatted INFO string for ( :info, \"Test\" )" do
    #   foo = capture_stdout do
    #   p  @logger.colorize( "Gray", "Message" ) #.should == "\e[1;30mMessage\e[0m"
    #   end
    #   @logger.message( :info, "Test" ).should == "\e[0;33m" + "Test" + "\e[0m"
    # end

  end # }}}


end # of describe Logger # }}}

# vim:ts=2:tw=100:wm=100
