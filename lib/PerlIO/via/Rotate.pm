package PerlIO::via::Rotate;

# Make sure we do things by the book
# Make sure we don't have any strange encoding issues
# Set the version info

use strict;
use bytes;
$PerlIO::via::Rotate::VERSION = '0.03';

# Initialize the base rotational strings

my @rotate = ('',qw(
 b-za
 c-zab
 d-za-c
 e-za-d
 f-za-e
 g-za-f
 h-za-g
 i-za-h
 j-za-i
 k-za-j
 l-za-k
 m-za-l
 n-za-m
 o-za-n
 p-za-o
 q-za-p
 r-za-q
 s-za-r
 t-za-s
 u-za-t
 v-za-u
 w-za-v
 x-za-w
 yza-x
 za-y
),'');

# Satisfy -require-

1;

#-----------------------------------------------------------------------
#  IN: 1 class to bless with
#      2..N parameters passed in -use-

sub import {

# Obtain the class we're working for
# Initialize to do all if so specified
# Set to do only rot13 if none specified

    my $class = shift;
    @_ = 0..26 if @_ == 1 and $_[0] eq ':all';
    @_ = 13 unless @_;

# For all of the rotations specified
#  Die now if it is an invalid rotation
#  Create the name of the version variable
#  Reloop now if already defined

    foreach (@_) {
        die "Invalid rotational value: $_" if !m#^\d+$# or $_ < 0 or $_ > 26;
	my $version = "PerlIO::via::rot$_\::VERSION";
        next if defined( $$version );

#  Initialize the source of the module for this rotation

        my $module = <<EOD;
package PerlIO::via::rot$_;
use bytes;
\@PerlIO::via::rot$_\::ISA = 'PerlIO::via::Rotate';
\$$version = '$PerlIO::via::Rotate::VERSION';
EOD

#  If there is an encoding string for this rotation
#   Calculate the rotation to get the original back
#   Calculate the decoding string for this rotation
#   Add the source code for this rotation (PUSHED is inherited)

        if (my $encode = $rotate[$_].uc( $rotate[$_] )) {
            my $other = 26 - $_;
            my $decode = $rotate[$other].uc( $rotate[$other] );
            $module .= <<EOD;
sub FILL {
    local \$_ = readline( \$_[1] );
    return unless defined \$_;
    tr/a-zA-Z/$decode/;
    \$_;
}
sub WRITE {
    local \$_ = \$_[1];
    tr/a-zA-Z/$encode/;
    (print {\$_[2]} \$_) ? length() : -1;
}
EOD
        }

# Make sure the code is parsed and available or die if failed

        eval $module or die "Could not create module for $_: $@";
    }
} #import

#-----------------------------------------------------------------------
#  IN: 1 class to bless with
#      2 mode string (ignored)
#      3 file handle of PerlIO layer below (ignored)
# OUT: 1 blessed object

sub PUSHED { bless \*PUSHED,$_[0] } #PUSHED

#-----------------------------------------------------------------------
#  IN: 1 instantiated object (ignored)
#      2 handle to read from
# OUT: 1 decoded string

sub FILL { 

# Obtain local copy of class of object
# Die now if one that is not supposed to inherit
# Read the line from the handle and return unaltered

    local( $_ ) = ref( $_[0] );
    die "Class $_ was not activated" unless m#::rot(?:0|26)$#;
    readline( $_[1] );
} #FILL

#-----------------------------------------------------------------------
#  IN: 1 instantiated object (ignored)
#      2 buffer to be written
#      3 handle to write to
# OUT: 1 number of bytes written

sub WRITE {

# Obtain local copy of class of object
# Die now if one that is not supposed to inherit
# Print the line unaltered and return the result

    local( $_ ) = ref( $_[0] );
    die "Class $_ was not activated" unless m#::rot(?:0|26)$#;
    (print {$_[2]} $_[1]) ? length($_[1]) : -1;
} #WRITE

__END__

=head1 NAME

PerlIO::via::Rotate - PerlIO layer for encoding using rotational deviation

=head1 SYNOPSIS

 use PerlIO::via::Rotate;           # assume rot13 only
 use PerlIO::via::Rotate 13,14,15;  # list rotations (rotxx) to be used
 use PerlIO::via::Rotate ':all';    # allow for all possible rotations 0..26

 open( my $in,'<:via(rot13)','file.rotated' )
  or die "Can't open file.rotated for reading: $!\n";
 
 open( my $out,'>:via(rot14)','file.rotated' )
  or die "Can't open file.rotated for writing: $!\n";

=head1 DESCRIPTION

This module implements a PerlIO layer that works on files encoded using
rotational deviation.  This is a simple manner of encoding in which
pure alphabetical letters (a-z and A-Z) are moved up a number of places in the
alphabet.

The default rotation is "13".  Commonly this type of encoding is referred to
as "rot13" encoding.  However, any rotation between 0 and 26 inclusive are
allowed (albeit that rotation 0 and 26 don't change anything).  You can
specify the rotations you would like to use as a list in the -use- statement.

The special keyword ":all" can be specified in the -use- statement to indicate
that all rotations between 0 and 26 inclusive should be allowed.

=head1 CAVEATS

This module is special insofar it serves as a front-end for 27 modules that
are named "PerlIO::via::rot0" through "PerlIO::via::rot26" that are eval'd as
appropriate when the module is -use-d.  The reason for this approach is that
it is currently impossible to pass parameters to a PerlIO layer when opening
a file.  The name of the module is the implicit parameter being passed to the
PerlIO::via::Rotate module.

=head1 SEE ALSO

L<PerlIO::via>, L<PerlIO::via::Base64>, L<PerlIO::via::MD5>,
L<PerlIO::via::QuotedPrint>, L<PerlIO::via::StripHTML>.

=head1 COPYRIGHT

Copyright (c) 2002 Elizabeth Mattijsen.  Inspired by Crypt::Rot13.pm by
Julian Fondren.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
