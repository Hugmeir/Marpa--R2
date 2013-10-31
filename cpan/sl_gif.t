#!perl
# Copyright 2013 Jeffrey Kegler
# This file is part of Marpa::R2.  Marpa::R2 is free software: you can
# redistribute it and/or modify it under the terms of the GNU Lesser
# General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Marpa::R2 is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser
# General Public License along with Marpa::R2.  If not, see
# http://www.gnu.org/licenses/.

# Tests which require only a GIF combination-- a grammar (G),
# input (I), and an (F) ASF output, with no semantics

use 5.010;
use strict;
use warnings;

use Test::More tests => 10;
use English qw( -no_match_vars );
use lib 'inc';
use Marpa::R2::Test;
use Marpa::R2;
use Data::Dumper;

my @tests_data = ();

my $aaaa_grammar = Marpa::R2::Scanless::G->new(
    {   source =>
\(<<'END_OF_SOURCE'),
    :start ::= quartet
    quartet ::= a a a a
    a ~ 'a'
END_OF_SOURCE
    }
);

push @tests_data, [
    $aaaa_grammar, 'aaaa',
    <<'END_OF_ASF',
CP3 Rule 1: quartet -> a a a a
  CP0 Symbol: a "a"
  CP6 Symbol: a "a"
  CP8 Symbol: a "a"
  CP10 Symbol: a "a"
END_OF_ASF
    'ASF OK',
    'Basic "a a a a" grammar'
] if 1;

my $bb_grammar = Marpa::R2::Scanless::G->new(
    {   source =>
\(<<'END_OF_SOURCE'),
:start ::= top
top ::= b b
b ::= a a
b ::= a
a ~ 'a'
END_OF_SOURCE
    }
);

push @tests_data, [
    $bb_grammar, 'aaa',
    <<'END_OF_ASF',
CP3 Rule 1: top -> b b
  Factoring #0
    CP5 Rule 2: b -> a a
      CP2 Symbol: a "a"
      CP0 Symbol: a "a"
    CP7 Rule 3: b -> a
      CP11 Symbol: a "a"
  Factoring #1
    CP4 Rule 3: b -> a
      CP14 Symbol: a "a"
    CP12 Rule 2: b -> a a
      CP16 Symbol: a "a"
      CP18 Symbol: a "a"
END_OF_ASF
    'ASF OK',
    '"b b" grammar'
] if 1;

my $seq_grammar = Marpa::R2::Scanless::G->new(
    {   source =>
\(<<'END_OF_SOURCE'),
:start ::= sequence
sequence ::= item+
item ::= pair | singleton
singleton ::= 'a'
pair ::= item item
END_OF_SOURCE
    }
);

push @tests_data, [
    $seq_grammar, 'aa',
    <<'END_OF_ASF',
CP3 Rule 1: sequence -> item+
  Factoring #0
    CP5 Rule 2: item -> pair
      CP7 Rule 5: pair -> item item
        CP8 Rule 3: item -> singleton
          CP11 Rule 4: singleton -> [Lex-0]
            CP0 Symbol: [Lex-0] "a"
        CP4 Rule 3: item -> singleton
          CP9 Rule 4: singleton -> [Lex-0]
            CP14 Symbol: [Lex-0] "a"
  Factoring #1
    CP8 already displayed
    CP4 already displayed
END_OF_ASF
    'ASF OK',
    'Sequence grammar for "aa"'
] if 1;

push @tests_data, [
    $seq_grammar, 'aaa',
    <<'END_OF_ASF',
CP3 Rule 1: sequence -> item+
  Factoring #0
    CP5 Rule 2: item -> pair
      CP7 Rule 5: pair -> item item
        Factoring #0.0
          CP9 Rule 3: item -> singleton
            CP12 Rule 4: singleton -> [Lex-0]
              CP14 Symbol: [Lex-0] "a"
          CP10 Rule 2: item -> pair
            CP8 Rule 5: pair -> item item
              CP16 Rule 3: item -> singleton
                CP19 Rule 4: singleton -> [Lex-0]
                  CP4 Symbol: [Lex-0] "a"
              CP6 Rule 3: item -> singleton
                CP17 Rule 4: singleton -> [Lex-0]
                  CP22 Symbol: [Lex-0] "a"
        Factoring #0.1
          CP0 Rule 2: item -> pair
            CP23 Rule 5: pair -> item item
              CP9 already displayed
              CP16 already displayed
          CP6 already displayed
  Factoring #1
    CP9 already displayed
    CP10 already displayed
  Factoring #2
    CP9 already displayed
    CP16 already displayed
    CP6 already displayed
  Factoring #3
    CP0 already displayed
    CP6 already displayed
END_OF_ASF
    'ASF OK',
    'Sequence grammar for "aaa"'
] if 1;

my $nulls_grammar = Marpa::R2::Scanless::G->new(
    {   source =>
\(<<'END_OF_SOURCE'),
:start ::= top
top ::= a a a a
a ::= 'a'
a ::=
END_OF_SOURCE
    }
);

push @tests_data, [
    $nulls_grammar, 'aaa',
    <<'END_OF_ASF',
CP3 Rule 1: top -> a a a a
  Factoring #0
    CP5 Rule 2: a -> [Lex-0]
      CP13 Symbol: [Lex-0] "a"
    CP7 Rule 2: a -> [Lex-0]
      CP15 Symbol: [Lex-0] "a"
    CP9 Rule 2: a -> [Lex-0]
      CP17 Symbol: [Lex-0] "a"
    CP11 Symbol: a ""
  Factoring #1
    CP5 already displayed
    CP7 already displayed
    CP19 Symbol: a ""
    CP9 already displayed
  Factoring #2
    CP5 already displayed
    CP21 Symbol: a ""
    CP7 already displayed
    CP9 already displayed
  Factoring #3
    CP23 Symbol: a ""
    CP5 already displayed
    CP7 already displayed
    CP9 already displayed
END_OF_ASF
    'ASF OK',
    'Nulls grammar'
] if 1;

TEST:
for my $test_data (@tests_data) {
    my ( $grammar, $test_string, $expected_value, $expected_result,
        $test_name )
        = @{$test_data};

    say STDERR "=== Test: $test_name";

    my ( $actual_value, $actual_result ) =
        my_parser( $grammar, $test_string );
    Marpa::R2::Test::is(
        Data::Dumper::Dumper( \$actual_value ),
        Data::Dumper::Dumper( \$expected_value ),
        qq{Value of $test_name}
    );
    Test::More::is( $actual_result, $expected_result,
        qq{Result of $test_name} );
} ## end TEST: for my $test_data (@tests_data)

sub my_parser {
    my ( $grammar, $string ) = @_;

    my $slr = Marpa::R2::Scanless::R->new( { grammar => $grammar } );

    if ( not defined eval { $slr->read( \$string ); 1 } ) {
        my $abbreviated_error = $EVAL_ERROR;
        chomp $abbreviated_error;
        $abbreviated_error =~ s/\n.*//xms;
        $abbreviated_error =~ s/^Error \s+ in \s+ string_read: \s+ //xms;
        return 'No parse', $abbreviated_error;
    } ## end if ( not defined eval { $slr->read( \$string ); 1 } )
    my $asf = Marpa::R2::Scanless::ASF->new( { slr => $slr } );
    if ( not defined $asf ) {
        return 'No ASF', 'Input read to end but no ASF';
    }

    say STDERR "Rules:\n",     $slr->thick_g1_grammar()->show_rules();
    say STDERR "IRLs:\n",      $slr->thick_g1_grammar()->show_irls();
    say STDERR "ISYs:\n",      $slr->thick_g1_grammar()->show_isys();
    say STDERR "Or-nodes:\n",  $slr->thick_g1_recce()->verbose_or_nodes();
    say STDERR "And-nodes:\n", $slr->thick_g1_recce()->show_and_nodes();
    say STDERR "Bocage:\n",    $slr->thick_g1_recce()->show_bocage();
    my $asf_desc = $asf->show();
    say STDERR $asf->show_nidsets();
    say STDERR $asf->show_powersets();
    return $asf_desc, 'ASF OK';

} ## end sub my_parser

# vim: expandtab shiftwidth=4:
