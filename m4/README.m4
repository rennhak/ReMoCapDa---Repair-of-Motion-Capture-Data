                                   REMOCAPDA
                              Version esyscmd( `git describe --tags' )



WHAT IS THE REMOCAPDA PROJECT ?

Repair of Motion Capture Data takes various input over the MotionX bridge and analyses and repairs
problems in a motion capture stream. This is achieved by using various input frames from T-Poses to
establish the body geometry and then calculating for each frame the approximate point poitions which
are suppose to be inside a certain (sane) threshhold.

If e.g. a marker is not detected by a mocap system such as Vicon then the point automatically is
placed at origin coordinates due to a empty value. REMOCAPDA takes such input and calculates the
correct value based on prior T-Pose configuration.

The result should be a repaired motion stream usable for your data processing needs.

EXAMPLE

Step 1
  Extract a proper config file describing the necessary measurements of the target body.
  Often this is extracted during the T-Pose phase. It extract crucial body measurements and angles
  necessary for Pose reconstruction, if markers are missing.

  ~# ./ReMoCapDa.rb -c -i input.vpm -t 134 -o input_tpose.yaml 

  This command will print colorized, uses the input.vpm motion capture file as input and uses
  specifically frame 134 as the measurement frame. Output config file is written to input_tpose.yaml
  which then later can be used to repair the input.vpm file.

Step 2
  In this step we repair the input vpm file by using the generated tpose.yaml config from step 1.

  ~# ./ReMoCapDa.rb -c -i input.vpm -c input_tpose.yaml -r -o output.vpm

  This command will print colorized, uses the input.vom motion capture file as input as well as
  input_tpose.yaml which holds the necessary repair information. The program receives -r which is used to signal
  that we want to repair the vpm file. The -o switch is used to pass along the target filename for the repaired
  data.


Step 3
  Manually verify that the repaired data is good, if not repeat previous steps.



`FEATURES'
define(FEATURES,esyscmd( `cat FEATURES.in | sed -e "s/#.*//" -e "/^$/d" -e "s/^\*\*/    o /" -e "s/^\*/\n  o /"' ))
FEATURES

ON WHAT HARDWARE DOES IT RUN?

    This Software was originally developed and tested on 32-bit x86 / SMP based PCs running on
    Ubuntu and Gentoo GNU/Linux 2.6.x. Other direct Linux and Unix derivates should be viable too as
    long as all dynamical linking dependencys are met. 


DOCUMENTATION


    A general developers API guide can be extracted from the Doxygen
    subdirectory which is able to generate HTML as well as PDF docs. Please refer to the
    [Rake|Make]file for additional information how to generate this documentation.


INSTALLING

    If you got this package as a packed tar.gz or tar.bz2 please unpack the contents in
    an appropriate folder e.g. ~/jokemachine/ and follow the supplied INSTALL or README
    documentation. Please delete or replace existing versions before unpacking/installing
    new ones.


SOFTWARE REQUIREMENTS

    This package was developed and compiled under Gentoo GNU/Linux 2.6.x with the Ruby 1.8.x MRI
    interpreter.


BUILD PROCESS

CONFIGURING

COMPILING

RUNNING

IF SOMETHING GOES WRONG

    In case you enconter bugs which seem to be related to the JOKESMACHINE package please check in
    the MAINTAINERS file for the associated person in charge and contact him or her directly. If
    there is no valid address then try to mail Bjoern Rennhak <bjoern AT rennhak DOT com> to get
    some basic assistance in finding the right person in charge of this section of the JOKESMACHINE
    project.


NOTES

    This README file was last modified on the $LastChangedDate$
    by $LastChangedBy$. Current file version is $Rev$ (which is a minor revision number) .


COPYRIGHT

    Please refer to the COPYRIGHT file in the various folders for explicit copyright notice.  Unless
    otherwise stated all remains protected and copyrighted by Bjoern Rennhak <bjoern AT rennhak DOT
    com>.


# vim:ts=2:tw=100:wm=100
