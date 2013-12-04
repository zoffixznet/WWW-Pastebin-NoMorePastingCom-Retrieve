#!/usr/bin/env perl

use strict;
use warnings;

my $URI = 'http://www.nomorepasting.com/getpaste.php?pasteid=13350';
my $ID  = 13350;

use Test::More tests => 15;

BEGIN {
    use_ok('WWW::Pastebin::Base::Retrieve');
    use_ok('HTML::TokeParser::Simple');
    use_ok('HTML::Entities');
	use_ok('WWW::Pastebin::NoMorePastingCom::Retrieve');
}

diag( "Testing WWW::Pastebin::NoMorePastingCom::Retrieve $WWW::Pastebin::NoMorePastingCom::Retrieve::VERSION, Perl $], $^X" );

my $o = WWW::Pastebin::NoMorePastingCom::Retrieve->new(timeout=>10);
isa_ok( $o, 'WWW::Pastebin::NoMorePastingCom::Retrieve');
can_ok($o, qw(_parse new retrieve uri id error _set_error _make_uri_and_id
                ));

isa_ok( $o->ua, 'LWP::UserAgent');

SKIP: {
    my $ret_ref = $o->retrieve( $URI );
    unless ( defined $ret_ref ) {
        diag "Got error while trying to fetch the test paste: " . $o->error;
        ok( (defined $o->error and length $o->error), 'error() method');
        skip "Got error..", 7;
    }

    is( ref $ret_ref, 'HASH',
        'retrieve() must return a hashref'
    );

    is_deeply( $ret_ref, _make_dump(),
        'return from retrieve() matches the dump'
    );

    is ( scalar keys %$ret_ref, 2,
        'return from retrieve() must have only two keys'
    );

    isa_ok( $o->uri, 'URI::http', 'uri() must return a URI object' );

    is( $o->uri, $URI, 'uri() must return our test URI');

    is( $o->id, $ID, 'id() must return the ID of the paste' );

    is( $o->content, $ret_ref->{content},
        'content() method must return out content'
    );

    is( "$o", $ret_ref->{content}, 'overloads');

}





sub _make_dump {
    return {
          "lang" => "Perl",
          "content" => "sub _parse {\n    my ( \$self, \$content ) = \@_;\n \n    my \$parser = HTML::TokeParser::Simple->new( \\\$content );\n \n    my %data = ( content => '' );\n    my %nav;\n    \@nav{ qw(level  look_for_data  store_data  get_lang) } = (0) x 4;\n \n    while ( my \$t = \$parser->get_token ) {\n        if ( \$t->is_start_tag('form')\n            and defined \$t->get_attr('id')\n            and \$t->get_attr('id') eq 'options'\n        ) {\n \n#etc"
        };
}