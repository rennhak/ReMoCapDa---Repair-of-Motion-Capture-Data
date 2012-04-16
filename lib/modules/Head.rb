#!/usr/bin/ruby
#

###
#
# File: Head.rb
#
######


###
#
# (c) 2012, Copyright, Bjoern Rennhak, The University of Tokyo
#
# @file       Head.rb
# @author     Bjoern Rennhak
#
#######


# Libaries
$:.push('..')
require 'Helpers.rb'


# @class      class Head # {{{
# @brief      The class Head takes motion capture data and checks if some markers are broken. If so it tries to repair it.
class Head

  # @fn       def initialize # {{{
  # @brief    Default constructor of the Head class
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


  # @fn       def repair_head? lfhd = nil, lbhd = nil, rfhd = nil, rbhd = nil, pt24 = nil # {{{
  # @brief    Checks if the head markers need repairing
  def repair_head? lfhd = nil, lbhd = nil, rfhd = nil, rbhd = nil, pt24 = nil, threshhold = @threshhold

    # check sanity
    raise ArgumentError, "lfhd can't be nil" if( lfhd.nil? )
    raise ArgumentError, "lbhd can't be nil" if( lbhd.nil? )
    raise ArgumentError, "rfhd can't be nil" if( rfhd.nil? )
    raise ArgumentError, "rbhd can't be nil" if( rbhd.nil? )
    raise ArgumentError, "pt24 can't be nil" if( pt24.nil? )

    result = false
    frame_head = []
    yaml_frame_head = []


    # Length of current frame
    # length of 4 sides
    frame_head << lf_lb_distance = @helpers.eucledian_distance( lfhd[0,3], lbhd[0,3] )
    frame_head << rf_rb_distance = @helpers.eucledian_distance( rfhd[0,3], rbhd[0,3] )
    frame_head << lf_rf_distance = @helpers.eucledian_distance( lfhd[0,3], rfhd[0,3] )
    frame_head << lb_rb_distance = @helpers.eucledian_distance( lbhd[0,3], rbhd[0,3] )

    # length of cross
    frame_head << lf_rb_distance = @helpers.eucledian_distance( lfhd[0,3], rbhd[0,3] )
    frame_head << lb_rf_distance = @helpers.eucledian_distance( lbhd[0,3], rfhd[0,3] )

    # Length of reference frame
    yaml_frame_head << yaml_lf_lb_distance = @helpers.eucledian_distance( get_array( @yaml.lfhd ), get_array( @yaml.lbhd ) )
    yaml_frame_head << yaml_rf_rb_distance = @helpers.eucledian_distance( get_array( @yaml.rfhd ), get_array( @yaml.rbhd ) )
    yaml_frame_head << yaml_lf_rf_distance = @helpers.eucledian_distance( get_array( @yaml.lfhd ), get_array( @yaml.rfhd ) )
    yaml_frame_head << yaml_lb_rb_distance = @helpers.eucledian_distance( get_array( @yaml.lbhd ), get_array( @yaml.rbhd ) )

    # length of cross
    yaml_frame_head << yaml_lf_rb_distance = @helpers.eucledian_distance( get_array( @yaml.lfhd ), get_array( @yaml.rbhd ) )
    yaml_frame_head << yaml_lb_rf_distance = @helpers.eucledian_distance( get_array( @yaml.lbhd ), get_array( @yaml.rfhd ) )

    diff        = frame_head.zip( yaml_frame_head ).map { |x,y| (y - x).abs }
    diff_sum    = diff.sum

    result = true if( diff_sum > threshhold )
    #if( result ) 
    #  p diff
    #  p diff_sum
    #end

    result
  end # }}}



  # @fn       def repair_head! lfhd = nil, lbhd = nil, rfhd = nil, rbhd = nil, pt24 = nil # {{{
  # @brief    Repairs head markers
  def repair_head! lfhd = nil, lbhd = nil, rfhd = nil, rbhd = nil, pt24 = nil, threshhold = @threshhold

    # check sanity
    raise ArgumentError, "lfhd can't be nil" if( lfhd.nil? )
    raise ArgumentError, "lbhd can't be nil" if( lbhd.nil? )
    raise ArgumentError, "rfhd can't be nil" if( rfhd.nil? )
    raise ArgumentError, "rbhd can't be nil" if( rbhd.nil? )
    raise ArgumentError, "pt24 can't be nil" if( pt24.nil? )

    @frame_head = []
    yaml_frame_head = []

    @lfhd, @lbhd, @rfhd, @rbhd, @pt24 = lfhd, lbhd, rfhd, rbhd, pt24

    # Length of reference frame
    yaml_frame_head << yaml_lf_lb_distance = @helpers.eucledian_distance( get_array( @yaml.lfhd ), get_array( @yaml.lbhd ) )
    yaml_frame_head << yaml_rf_rb_distance = @helpers.eucledian_distance( get_array( @yaml.rfhd ), get_array( @yaml.rbhd ) )
    yaml_frame_head << yaml_lf_rf_distance = @helpers.eucledian_distance( get_array( @yaml.lfhd ), get_array( @yaml.rfhd ) )
    yaml_frame_head << yaml_lb_rb_distance = @helpers.eucledian_distance( get_array( @yaml.lbhd ), get_array( @yaml.rbhd ) )

    # length of cross
    yaml_frame_head << yaml_lf_rb_distance = @helpers.eucledian_distance( get_array( @yaml.lfhd ), get_array( @yaml.rbhd ) )
    yaml_frame_head << yaml_lb_rf_distance = @helpers.eucledian_distance( get_array( @yaml.lbhd ), get_array( @yaml.rfhd ) )

    # Length of current frame
    # length of 4 sides
    @frame_head << lf_lb_distance = @helpers.eucledian_distance( @lfhd[0,3], @lbhd[0,3] )
    @frame_head << rf_rb_distance = @helpers.eucledian_distance( @rfhd[0,3], @rbhd[0,3] )
    @frame_head << lf_rf_distance = @helpers.eucledian_distance( @lfhd[0,3], @rfhd[0,3] )
    @frame_head << lb_rb_distance = @helpers.eucledian_distance( @lbhd[0,3], @rbhd[0,3] )

    # length of cross
    @frame_head << lf_rb_distance = @helpers.eucledian_distance( @lfhd[0,3], @rbhd[0,3] )
    @frame_head << lb_rf_distance = @helpers.eucledian_distance( @lbhd[0,3], @rfhd[0,3] )

    @diff        = @frame_head.zip( yaml_frame_head ).map { |x,y| (y - x).abs }

    # find out which distance is ok
    @good_distance = []  # true == length is ok
    @diff.each { |n| @good_distance << ( n < threshhold ) ? ( false ) : ( true ) } 

    # Iterate over markers until repaired
    while( @good_distance.include?( false ) )

      @frame_head = []

      @logger.message( :debug, "Iterating over good distance check for frame until it is fixed" )

      # Length of current frame
      # length of 4 sides
      @frame_head << lf_lb_distance = @helpers.eucledian_distance( @lfhd[0,3], @lbhd[0,3] )
      @frame_head << rf_rb_distance = @helpers.eucledian_distance( @rfhd[0,3], @rbhd[0,3] )
      @frame_head << lf_rf_distance = @helpers.eucledian_distance( @lfhd[0,3], @rfhd[0,3] )
      @frame_head << lb_rb_distance = @helpers.eucledian_distance( @lbhd[0,3], @rbhd[0,3] )

      @frame_head << lf_rb_distance = @helpers.eucledian_distance( @lfhd[0,3], @rbhd[0,3] )
      @frame_head << lb_rf_distance = @helpers.eucledian_distance( @lbhd[0,3], @rfhd[0,3] )

      @diff        = @frame_head.zip( yaml_frame_head ).map { |x,y| (y - x).abs }

      # find out which distance is ok
      @good_distance = []
      @diff.each { |n| @good_distance << ( n < threshhold ) ? ( false ) : ( true ) } 

      break unless( @good_distance.include?( false ) )

      if( @good_distance[0] )  # lfhd <-> lbhd is ok

        @rfhd[0]  = @lfhd[0] - (@yaml.lfhd.xtran.abs - @yaml.rfhd.xtran.abs)
        @rfhd[1]  = @lfhd[1]
        @rfhd[2]  = @lfhd[2]

        @rbhd[0]  = @lbhd[0] - (@yaml.lbhd.xtran.abs - @yaml.rbhd.xtran.abs)
        @rbhd[1]  = @lbhd[1]
        @rbhd[2]  = @lbhd[2]

        next
      end

      if( @good_distance[1] )  # rfhd <-> rbhd is ok
        @logger.message( :debug, "Distance rfhd<->rbhd is ok, using this as a basis" )

        # FIXME: Calculate angle between lines

        # TOP VIEW

        # lfhd   rfhd
        #   o     o
        #
        #      o pt24
        #   o     o
        # lbhd   rbhd

        @lfhd[0]  = @rfhd[0] - (@yaml.rfhd.xtran.abs - @yaml.lfhd.xtran.abs)
        @lfhd[1]  = @rfhd[1]
        @lfhd[2]  = @rfhd[2]

        @lbhd[0]  = @rbhd[0] - (@yaml.rbhd.xtran.abs - @yaml.lbhd.xtran.abs)
        @lbhd[1]  = @rbhd[1]
        @lbhd[2]  = @rbhd[2]

        # This is a naive method
        #@lfhd[0]  = @yaml.lfhd.xtran
        #@lfhd[1]  = @yaml.lfhd.ytran
        #@lfhd[2]  = @yaml.lfhd.ztran

        #@lbhd[0]  = @yaml.lbhd.xtran
        #@lbhd[1]  = @yaml.lbhd.ytran
        #@lbhd[2]  = @yaml.lbhd.ztran

        next
      end

      if( @good_distance[2] )  # lfhd <-> rfhd is ok
        @logger.message( :debug, "Distance lfhd<->rfhd is ok, using this as a basis" )

        @lbhd[0]  = @lfhd[0]
        #@lbhd[1]  = @lfhd[1]
        #@lbhd[2]  = @lfhd[2] - (@yaml.lfhd.ztran.abs - @yaml.lbhd.ztran.abs)

        @rbhd[0]  = @rfhd[0]
        #@rbhd[1]  = @rfhd[1]
        #@rbhd[2]  = @rfhd[2] - (@yaml.rfhd.ztran.abs - @yaml.rbhd.ztran.abs)

        # This is a naive method
        # @lbhd[0]  = @yaml.lbhd.xtran
        @lbhd[1]  = @yaml.lbhd.ytran
        @lbhd[2]  = @yaml.lbhd.ztran

        # @rbhd[0]  = @yaml.rbhd.xtran
        @rbhd[1]  = @yaml.rbhd.ytran
        @rbhd[2]  = @yaml.rbhd.ztran

        next
      end

      if( @good_distance[3] )  # lbhd <-> rbhd is ok
        raise NotImplementedError
        next
      end

      if( @good_distance[4] )  # lfhd <-> rbhd is ok
        raise NotImplementedError
        next
      end

      if( @good_distance[5] )  # lbhd <-> rfhd is ok
        raise NotImplementedError
        next
      end

    end # of while


    # Recalculate pt24
    @pt24[0] = ( @lfhd[0] + @lbhd[0] + @rfhd[0] + @rbhd[0] ) / 4
    @pt24[1] = ( @lfhd[1] + @lbhd[1] + @rfhd[1] + @rbhd[1] ) / 4
    @pt24[2] = ( @lfhd[2] + @lbhd[2] + @rfhd[2] + @rbhd[2] ) / 4

    [ @lfhd, @lbhd, @rfhd, @rbhd, @pt24 ]
  end # }}}


  def get_array openstruct
    result = []

    result << openstruct.xtran
    result << openstruct.ytran
    result << openstruct.ztran

    result
  end



end # of class Head }}}


# Direct Invocation (local testing) # {{{
if __FILE__ == $0
end # of if __FILE__ == $0 }}}

# vim:ts=2:tw=100:wm=100
