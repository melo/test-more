package Test::Builder2::Streamer::JUnit;

use Test::Builder2::Mouse;
extends 'Test::Builder2::Streamer::Print';

### Need this error_fh to please Test::Builder
has error_fh  =>
  is            => 'rw',
#  isa           => 'FileHandle',
  default       => *STDERR,
;

my %Dest_Dest = (
    out => 'output_fh',
    err => 'error_fh',
);

sub write {
    my $self = shift;
    my $dest = shift;

    confess "unknown stream destination" if ! exists $Dest_Dest{ $dest };

    my $fh_method = $Dest_Dest{ $dest };
    my $fh = $self->$fh_method;

    # This keeps "use Test::More tests => 2" from printing stuff when
    # compiling with -c.
    return if $^C;

    $self->safe_print($fh, @_);
}


no Test::Builder2::Mouse;
1;
