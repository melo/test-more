#!perl -w

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = ('../lib', 'lib');
    }
    else {
        unshift @INC, 't/lib';
    }
}
chdir 't';


use MyTestBuilder;
my $Test = MyTestBuilder->create;
$Test->plan( tests => 4 );

sub ok { $Test->ok(@_) }
sub is { $Test->is_eq(@_) }


use TieOut;
use Test::Builder;
my $tb = Test::Builder->new();

my $result;
my $tmpfile = 'foo.tmp';
my $out = $tb->output($tmpfile);
END { 1 while unlink($tmpfile) }

ok( defined $out );

print $out "hi!\n";
close *$out;

undef $out;
open(IN, $tmpfile) or die $!;
chomp(my $line = <IN>);
close IN;

is($line, 'hi!');

open(FOO, ">>$tmpfile") or die $!;
$out = $tb->output(\*FOO);
$old = select *$out;
print "Hello!\n";
close *$out;
undef $out;
select $old;
open(IN, $tmpfile) or die $!;
my @lines = <IN>;
close IN;

ok($lines[1] =~ /Hello!/);



# Ensure stray newline in name escaping works.
$out = tie *FAKEOUT, 'TieOut';
$tb->output(\*FAKEOUT);
$tb->exported_to(__PACKAGE__);
$tb->no_ending(1);
$tb->plan(tests => 5);

$tb->ok(1, "ok");
$tb->ok(1, "ok\n");
$tb->ok(1, "ok, like\nok");
$tb->skip("wibble\nmoof");
$tb->todo_skip("todo\nskip\n");

my $output = $out->read;
$Test->core_tap_ok( $output, <<OUTPUT ) || print STDERR $output;
1..5
ok 1 - ok
ok 2 - ok
# 
ok 3 - ok, like
# ok
ok 4 # skip wibble
# moof
not ok 5 # TODO & SKIP todo
# skip
# 
OUTPUT
