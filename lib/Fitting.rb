#!/usr/bin/ruby19
#

###
#
# File: Fitting.rb
#
######


###
#
# (c) 2012, Copyright, Bjoern Rennhak, The University of Tokyo
#
# @file       Fitting.rb
# @author     Bjoern Rennhak
#
#######


# Standard includes
require 'rubygems'
require 'narray'
require 'gsl'

# Local includes
$:.push('.')
require 'Logger.rb'
require 'Mathematics.rb'

# Change Namespace
include GSL


# @class      Class Fitting # {{{
# @brief      The class Fitting takes input data and fits a polynom to it
class Fitting


  # @fn       def initialize options, from, to # {{{
  # @brief    Custom constructor for the Filter class
  #
  # @param    [Logger]         logger          Logging class instance
  def initialize logger = nil

    # Input verification {{{
    raise ArgumentError, "Logger cannot be nil"   if( logger.nil? )
    # }}}

    @mathematics          = Mathematics.new
    @logger               = logger
  end # of def initialize }}}


  # @fn       def filter_motion_capture_data input, point_window = @options.filter_point_window_size, polynom_order = @options.filter_polyomial_order # {{{
  # @brief    The function takes input arrays and returns a filtered (smoothed) version of the input data via an overlapping sliding point window that uses a polynomial for fitting
  #
  # @param    [Array]   input           Input arrays, subarrays are [x,y,z]
  # @param    [Integer] point_window    Integer representing the window size in which the polynomial fitting is applied
  # @param    [Integer] polynom_order   Integer representing the order of the fitting polynomial
  def filter_motion_capture_data input, point_window = 20, polynom_order = 5

    @log.message :success, "Smoothing raw data with Polynomial of the order #{polynom_order.to_s} with a point window of #{point_window.to_s}"

    # Pre-condition check {{{
    raise ArgumentError, "Point window argument should be of type Integer, but is of (#{point_window.class.to_s})" unless( point_window.is_a?( Integer ) )
    raise ArgumentError, "Polynom order argument should be of type Integer, but is of (#{polynom_order.class.to_s})" unless( polynom_order.is_a?( Integer ) )
    # }}}

    @log.message :info, "Starting filtering of all relevant motion segments"

    # we store our calculated chunks here
    temp_container = []
    errors         = []

    coordinates    = input # expecting array

    coordinate_chunks = coordinates % ( point_window / 2 )

    while( not coordinate_chunks.empty? )

      # cluster = c1 + c2 since we have point_window / 2
      c1 = coordinate_chunks.shift
      c1_length = c1.length

      c2 = coordinate_chunks.shift
      c2_length = ( c2.nil? ) ? ( 0 ) : ( c2.length )

      cluster = ( c2.nil? ) ? ( c1 ) : ( c1.dup.concat( c2 ) )

      unless( cluster.empty? )
        # determine the piecewise linear from p0 to p1 (eucleadian distance)
        arc_lengths  = []
        cluster.each_index { |index| arc_lengths << @mathematics.eucledian_distance( cluster[index], cluster[index+1] ) unless( (cluster[ index + 1 ]).nil? ) }

        cluster_l           = cluster
        x, y, z             = cluster_l.shift, cluster_l.shift, cluster_l.shift

        t_s         = []
        arc_lengths.each_index do |i|
          # t[0] is 0
          if( i == 0 )
            t_s << 0
            next
          end

          # from 2..n
          t_s << t_s[ i - 1 ] + arc_lengths[ i ]
        end

        result_splines = []

        # get independent splines through s1 = [ t(i), x(i) ], s2 =[ t(i), y(i) ], s3 = [ t(i), z(i) ]
        # Should use bsline actually, maybe to wavevy?
        [ [ t_s, x ], [ t_s, y ], [ t_s, z ] ].each do |array|

          t, axis = *array

          # original
          # can we not throw away the last point?
          # if( t.length != axis.length )
          #  t_l, a_l = t.length, axis.length
          #  if( t_l < a_l )
          #    axis.pop
          #  end
          # end

          if( t.length != axis.length )
            t_l, a_l = t.length, axis.length
            if( t_l < a_l )
              # t << axis.last
              t << t.last # best guess?
            end
          end

          if( t.include?( nil ) or axis.include?( nil ) )
            puts "--- Something bad happend just now in the filter class"
            next
          end

          gsl_t, gsl_axis           = GSL::Vector.alloc( t ), GSL::Vector.alloc( axis )
          coef, err, chisq, status  = GSL::MultiFit::polyfit( gsl_t, gsl_axis, polynom_order )

          # result_splines << [ coef, err, chisq, status ]
          result_splines << coef

          # Standard error estimate
          #err_sum = err.to_na.to_a.inject(0) { |r,e| r + e }
          #err_final = Math.sqrt( err_sum / ( ( err.to_na.to_a.length - 1 ) - 2 ) )
          
          # FIXME: This was not uncommented before (23/02/2012)
          #errors += err.to_na.to_a
          # printf( "Error: %-20s\n", err_final.to_s )
        end

        cluster_smooth  = []
        s1_coef, s2_coef, s3_coef = *result_splines

        t_s.each_index do |i|
    
          if( t_s[i].nil? )
            puts "--- Somthing bad happend just now in the filter class (lower)"
            next
          end

          s1_t, s2_t, s3_t = s1_coef.eval( t_s[i] ), s2_coef.eval( t_s[i] ), s3_coef.eval( t_s[i] )

          cluster_smooth << [ s1_t, s2_t, s3_t ]
        end

        x1 = cluster_smooth.shift( c1_length )
        x2 = cluster_smooth.shift( c2_length )

        # temp_container += cluster_smooth
        temp_container += x1
        coordinate_chunks.insert(0, x2)
      else
        # cluster is empty
      end

    end # while
    # end # of coordinate_chunks.each do |cluster|


    # t_container = pca.reshape_data( temp_container, true, false )

    xtran, ytran, ztran = t_container.shift, t_container.shift, t_container.shift

    [xtran, ytran, ztran]
  end # of def motion_capture_data_smoothing }}}


end # of class Fitting }}}


# Direct Invocation (local testing) # {{{
if __FILE__ == $0
end # of if __FILE__ == $0 }}}

# vim:ts=2:tw=100:wm=100
