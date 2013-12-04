#!/usr/bin/env perl

use strict;
use warnings;

use lib '../lib';
use WWW::Pastebin::NoMorePastingCom::Retrieve;

die "Usage: perl retrieve.pl <paste_ID_or_URI>\n"
    unless @ARGV;

my $Paste = shift;

my $paster = WWW::Pastebin::NoMorePastingCom::Retrieve->new;

my $results_ref = $paster->retrieve( $Paste )
    or die 'Error: ' . $paster->error;

printf "Paste language is: %s\n%s\n",
            @$results_ref{ qw(lang content) };
