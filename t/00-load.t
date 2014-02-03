#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Text::Nimble' ) || print "Bail out!\n";
}

diag( "Testing Text::Nimble $Text::Nimble::VERSION, Perl $], $^X" );
