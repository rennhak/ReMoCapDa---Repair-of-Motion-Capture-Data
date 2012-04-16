#!/usr/bin/ruby
#

###
#
# File: Hands.rb
#
######


###
#
# (c) 2012, Copyright, Bjoern Rennhak, The University of Tokyo
#
# @file       Hands.rb
# @author     Bjoern Rennhak
#
#######


# Libaries
$:.push('..')
require 'Helpers.rb'


# @class      class Hands # {{{
# @brief      The class Hands takes motion capture data and checks if some markers are broken. If so it tries to repair it.
class Hands

  # @fn       def initialize # {{{
  # @brief    Default constructor of the Hands class
  #
  # @param    [Logger]        logger        Logger class
  # @param    [OpenStruct]    yaml          OpenStruct containing the loaded yaml
  # @param    [Fixnum]        threshhold    Threshhold for the repair detection
  def initialize logger = nil, yaml = nil, threshhold = nil

    # Sanity check
    raise ArgumentError, "Logger can't be nil" if( logger.nil? )
    raise ArgumentError, "Yaml can't be nil" if( yaml.nil? )
    raise ArgumentError, "Threshhold can't be nil" if( threshhold.nil? )

    @logger       = logger
    @yaml         = yaml
    @threshhold   = threshhold
    @helpers      = Helpers.new

    # Go through markers and correct where incorrect 0..n
    @keys         = yaml.instance_variable_get("@table").keys

  end # of def initialize }}}


  # @fn         def repair_hand?  # {{{
  # @brief      Checks if the hand markers need repairing
  #
  # @param      [Array]         rwra        Array for the rwra marker
  # @param      [Array]         rwrb        Array for the rwrb marker
  # @param      [Array]         lwra        Array for the lwra marker
  # @param      [Array]         lwrb        Array for the lwrb marker
  # @param      [Array]         lfin        Array for the lfin marker
  # @param      [Array]         rfin        Array for the rfin marker
  # @param      [Fixnum]        threshhold  Threshhold to determine if a marker is broken or not
  #
  # @return                               Returns boolean, true if needs to be repaired, false if not.
  def repair_hand? rwra = nil, rwrb = nil, lwra = nil, lwrb = nil, lfin = nil, rfin = nil, threshhold = @threshhold

    # check sanity
    raise ArgumentError, "rwra can't be nil" if( rwra.nil? )
    raise ArgumentError, "rwrb can't be nil" if( rwrb.nil? )
    raise ArgumentError, "lwra can't be nil" if( lwra.nil? )
    raise ArgumentError, "lwrb can't be nil" if( lwrb.nil? )
    raise ArgumentError, "lfin can't be nil" if( lfin.nil? )
    raise ArgumentError, "rfin can't be nil" if( rfin.nil? )
    raise ArgumentError, "threshhold can't be nil" if( threshhold.nil? )


    result = false
    frame_hand = []
    yaml_frame_hand = []


    # Fingers
    frame_hand << rfin_rwra_distance = @helpers.eucledian_distance( rfin[0,3], rwra[0,3] )
    frame_hand << rfin_rwrb_distance = @helpers.eucledian_distance( rfin[0,3], rwrb[0,3] )

    frame_hand << lfin_lwra_distance = @helpers.eucledian_distance( lfin[0,3], lwra[0,3] )
    frame_hand << lfin_lwrb_distance = @helpers.eucledian_distance( lfin[0,3], lwrb[0,3] )

    # Wrist
    frame_hand << rwra_rwrb_distance = @helpers.eucledian_distance( rwra[0,3], rwra[0,3] )
    frame_hand << lwra_lwrb_distance = @helpers.eucledian_distance( lwrb[0,3], lwrb[0,3] )

    # Fingers
    yaml_frame_hand << yaml_rfi_lb_distance = @helpers.eucledian_distance( get_array( @yaml.lfhd ), get_array( @yaml.lbhd ) )

    # Fingers
    yaml_frame_hand << yaml_rfin_rwra_distance = @helpers.eucledian_distance( get_array( @yaml.rfin), get_array( @yaml.rwra ) )
    yaml_frame_hand << yaml_rfin_rwrb_distance = @helpers.eucledian_distance( get_array( @yaml.rfin), get_array( @yaml.rwrb ) )

    yaml_frame_hand << yaml_lfin_lwra_distance = @helpers.eucledian_distance( get_array( @yaml.lfin), get_array( @yaml.lwra ) )
    yaml_frame_hand << yaml_lfin_lwrb_distance = @helpers.eucledian_distance( get_array( @yaml.lfin), get_array( @yaml.lwrb ) )

    # Wrist
    yaml_frame_hand << yaml_rwra_rwrb_distance = @helpers.eucledian_distance( get_array( @yaml.rwra), get_array( @yaml.rwra ) )
    yaml_frame_hand << yaml_lwra_lwrb_distance = @helpers.eucledian_distance( get_array( @yaml.lwrb), get_array( @yaml.lwrb ) )

    diff        = frame_hand.zip( yaml_frame_hand ).map { |x,y| (y - x).abs }
    diff_sum    = diff.sum

    if( diff_sum > threshhold )
      result = true 

      # puts "--- Diff_sum (#{diff_sum.to_s}) -> Threshhold (#{threshhold.to_s})"
    end

    result
  end # }}}


  # @fn       def repair_hand!  # {{{
  # @brief    Repairs hand markers
  def repair_hand! rwra = nil, rwrb = nil, lwra = nil, lwrb = nil, lfin = nil, rfin = nil, threshhold = @threshhold
    @logger.message( :warning, "Reparing hand" )

    @rwra, @rwrb, @lwra, @lwrb, @lfin, @rfin = rwra, rwrb, lwra, lwrb, lfin, rfin

    # check sanity
    raise ArgumentError, "rwra can't be nil" if( rwra.nil? )
    raise ArgumentError, "rwrb can't be nil" if( rwrb.nil? )
    raise ArgumentError, "lwra can't be nil" if( lwra.nil? )
    raise ArgumentError, "lwrb can't be nil" if( lwrb.nil? )
    raise ArgumentError, "lfin can't be nil" if( lfin.nil? )
    raise ArgumentError, "rfin can't be nil" if( rfin.nil? )

    result = false
    @frame_hand = []
    yaml_frame_hand = []


    # Fingers
    @frame_hand << rfin_rwra_distance = @helpers.eucledian_distance( @rfin[0,3], @rwra[0,3] )
    @frame_hand << rfin_rwrb_distance = @helpers.eucledian_distance( @rfin[0,3], @rwrb[0,3] )

    @frame_hand << lfin_lwra_distance = @helpers.eucledian_distance( @lfin[0,3], @lwra[0,3] )
    @frame_hand << lfin_lwrb_distance = @helpers.eucledian_distance( @lfin[0,3], @lwrb[0,3] )

    # Wrist
    @frame_hand << rwra_rwrb_distance = @helpers.eucledian_distance( @rwra[0,3], @rwra[0,3] )
    @frame_hand << lwra_lwrb_distance = @helpers.eucledian_distance( @lwrb[0,3], @lwrb[0,3] )

    # Fingers
    yaml_frame_hand << yaml_rfin_rwra_distance = @helpers.eucledian_distance( get_array( @yaml.rfin), get_array( @yaml.rwra ) )
    yaml_frame_hand << yaml_rfin_rwrb_distance = @helpers.eucledian_distance( get_array( @yaml.rfin), get_array( @yaml.rwrb ) )

    yaml_frame_hand << yaml_lfin_lwra_distance = @helpers.eucledian_distance( get_array( @yaml.lfin), get_array( @yaml.lwra ) )
    yaml_frame_hand << yaml_lfin_lwrb_distance = @helpers.eucledian_distance( get_array( @yaml.lfin), get_array( @yaml.lwrb ) )

    # Wrist
    yaml_frame_hand << yaml_rwra_rwrb_distance = @helpers.eucledian_distance( get_array( @yaml.rwra), get_array( @yaml.rwra ) )
    yaml_frame_hand << yaml_lwra_lwrb_distance = @helpers.eucledian_distance( get_array( @yaml.lwrb), get_array( @yaml.lwrb ) )

    @diff        = @frame_hand.zip( yaml_frame_hand ).map { |x,y| (y - x).abs }

    # find out which distance is ok
    @good_distance = []  # true == length is ok
    @diff.each do |n| 
      p n
      @good_distance << ( n < threshhold ) ? ( true ) : ( false ) 
      p @good_distance
      STDIN.gets
    end

    # Iterate over markers until repaired
    while( @good_distance.include?( false ) )

      @frame_hand = []

      @logger.message( :debug, "Iterating over good distance check for hand frame until it is fixed" )

      # Fingers
      @frame_hand << rfin_rwra_distance = @helpers.eucledian_distance( @rfin[0,3], @rwra[0,3] )
      @frame_hand << rfin_rwrb_distance = @helpers.eucledian_distance( @rfin[0,3], @rwrb[0,3] )

      @frame_hand << lfin_lwra_distance = @helpers.eucledian_distance( @lfin[0,3], @lwra[0,3] )
      @frame_hand << lfin_lwrb_distance = @helpers.eucledian_distance( @lfin[0,3], @lwrb[0,3] )

      # Wrist
      @frame_hand << rwra_rwrb_distance = @helpers.eucledian_distance( @rwra[0,3], @rwra[0,3] )
      @frame_hand << lwra_lwrb_distance = @helpers.eucledian_distance( @lwrb[0,3], @lwrb[0,3] )


      @diff        = @frame_hand.zip( yaml_frame_hand ).map { |x,y| (y - x).abs }

      # find out which distance is ok
      @good_distance = []
      @diff.each { |n| @good_distance << ( n > threshhold ) ? ( false ) : ( true ) } 

      break unless( @good_distance.include?( false ) )

      if( @good_distance[0] )  # rfin <-> rwra is ok
        raise NotImplementedError
        next
      end

      if( @good_distance[1] )  # rfin <-> rwrb is ok
        @logger.message( :warning," ---> Repair" )
        @rwra[0]  = @rwrb[0] - (@yaml.rwrb.xtran.abs - @yaml.rwra.xtran.abs)
        @rwra[1]  = @rwrb[1]
        @rwra[2]  = @rwrb[2]

        next
      end

      if( @good_distance[2] )  # lfin <-> lwra is ok
        raise NotImplementedError
        next
      end
 
      if( @good_distance[3] )  # lfin <-> lwrb is ok
        raise NotImplementedError
        next
      end

      if( @good_distance[4] )  # rwra <-> rwrb is ok
        raise NotImplementedError
        next
      end

      if( @good_distance[5] )  # lwra lwrb is ok
        raise NotImplementedError
        next
      end

    end # of while

    [ @rwra, @rwrb, @lwra, @lwrb, @lfin, @rfin ]
  end # }}}




  def get_array openstruct
    result = []

    result << openstruct.xtran
    result << openstruct.ytran
    result << openstruct.ztran

    result
  end


end # of class Hands }}}


# Direct Invocation (local testing) # {{{
if __FILE__ == $0
end # of if __FILE__ == $0 }}}

# vim:ts=2:tw=100:wm=100
