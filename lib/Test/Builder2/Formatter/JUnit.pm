package Test::Builder2::Formatter::JUnit;

use Test::Builder2::Mouse;
use XML::Generator;
use Data::Dump 'pp';

# TAP::Formatter::JUnit
extends 'Test::Builder2::Formatter';

# TODO: add timer stuff as in TAP::Formatter::JUnit (should be moved to TB2 though)

sub default_streamer_class {'Test::Builder2::Streamer::JUnit'}

has 'xml' => (isa => 'XML::Generator', is => 'ro', lazy_build => 1);

sub _build_xml {
  return XML::Generator->new(
    ':pretty',
    ':std',
    'escape'   => 'always,high-bit,even-entities',
    'encoding' => 'UTF-8',
  );
}

has 'name' => (isa => 'Str', is => 'rw');
has 'tests' => (isa => 'ArrayRef', is => 'ro', default => sub { [] });


sub INNER_begin { }

sub INNER_result {
  my ($self, $result) = @_;

  ## COMPAT TAP: the counter is in the formatter
  $result->test_number($self->counter->increment)
    unless $result->test_number;

  $self->name($result->file);
  push @{$self->tests}, $result;

  return;
}

sub INNER_end {
  my ($self) = @_;
  my $xml    = $self->xml;
  my $tests  = $self->tests;

  my $n_tests = scalar(@$tests);
  my $n_fail  = 0;

  for my $r (@$tests) {
    my $name = _get_testcase_name($r);
    my $desc = $r->description;    ## TODO: what to do with this if success?
    my $fail = $self->_gen_xml_for_bad_stuff($r);

    $n_fail++ if $fail;

    $r = $xml->testcase({name => $name}, $fail);
  }

  my %attrs = (
    name     => _get_testsuite_name($self->name),
    tests    => $n_tests,
    failures => $n_fail,
    errors   => 0,
  );
  $self->write(out => $xml->testsuite(\%attrs, @$tests));
}


### Utils

sub _gen_xml_for_bad_stuff {
  my ($self, $result) = @_;
  my $bogus;

  if ($result->is_todo && $result->is_pass) {
    $bogus = {
      level => 'error',
      type  => 'TodoTestSucceeded',
    };
  }
  elsif ($result->is_todo && !$result->is_pass) {
    ## TODO: mark as <skiped />?
  }
  elsif ($result->is_fail) {
    $bogus = {
      level => 'failure',
      type  => 'TestFailed',
    };
  }

  return unless $bogus;

  my $level = $bogus->{level};
  return $self->xml->$level(
    { type    => $bogus->{type},
      message => $result->description,
    }
  );
}


### Stuff stolen from TAP::Formatter::JUnit

sub _get_testcase_name {
  my ($test) = shift;
  my $name =
    join(' ', $test->test_number, _squeaky_clean($test->description));
  $name =~ s/\s+$//;
  return $name;
}

sub _squeaky_clean {
  my $string = shift;

  # control characters (except CR and LF)
  $string =~ s/([\x00-\x09\x0b\x0c\x0e-\x1f])/"^".chr(ord($1)+64)/ge;

  # high-byte characters
  $string =~ s/([\x7f-\xff])/'[\\x'.sprintf('%02x',ord($1)).']'/ge;
  return $string;
}

sub _get_testsuite_name {
  my ($path) = @_;
  $path =~ s{^\./}{};
  $path =~ s{^t/}{};
  $path =~ s/[^-:_A-Za-z0-9]+/_/gs;

  return $path;
}



1;
