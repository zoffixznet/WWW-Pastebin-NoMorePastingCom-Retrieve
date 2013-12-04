package WWW::Pastebin::NoMorePastingCom::Retrieve;

use warnings;
use strict;

our $VERSION = '0.001';

use base 'WWW::Pastebin::Base::Retrieve';
use HTML::TokeParser::Simple;
use HTML::Entities;

sub _make_uri_and_id {
    my ( $self, $what ) = @_;

    my ( $id ) = $what =~ m{^
            (?:http://)?
            (?:www\.)?
            \Qnomorepasting.com/getpaste.php?\E
            .*? pasteid=
            (\d+) # this is the digitz of paste ID
    }xi;

    $id = $what
        unless defined $id;

    $id =~ s/^\s+|\s+$//g;

#     $id =~ /\D/
#         and return $self->_set_error('ID is not numeric');

    return (
        URI->new("http://www.nomorepasting.com/getpaste.php?pasteid=$id"),
        $id
    );
}

sub _parse {
    my ( $self, $content ) = @_;

    my $parser = HTML::TokeParser::Simple->new( \$content );

    my %data = ( content => '' );
    my %nav;
    @nav{ qw(level  look_for_data  store_data  get_lang) } = (0) x 4;

    while ( my $t = $parser->get_token ) {
        if ( $t->is_start_tag('form')
            and defined $t->get_attr('id')
            and $t->get_attr('id') eq 'options'
        ) {
            @nav{ qw(level look_for_data) } = (1, 1);
        }
        elsif ( $nav{look_for_data} == 1 and $t->is_start_tag('pre') ) {
            @nav{ qw(level  look_for_data  store_data) } = (2, 2, 1);
        }
        elsif ( $nav{store_data} and $t->is_end_tag('pre') ) {
            @nav{ qw(level store_data) } = (3, 0);
        }
        elsif ( $nav{store_data} and $t->is_text ) {
            $data{content} .= $t->as_is;
            $nav{level} = 4;
        }
        elsif (
            $t->is_start_tag('option') and defined $t->get_attr('selected')
        ) {
            @nav{ qw(level get_lang) } = (5, 1);
        }
        elsif ( $nav{get_lang} and $t->is_text ) {
            $data{lang} = $t->as_is;
            $nav{is_success} = 1;
            last;
        }
        elsif ( $t->is_end_tag('body') and $nav{look_for_data} == 1 ) {
            return $self->_set_error('This paste ID does not seem to exist');
        }
    }

    return $self->_set_error(
        "Parser error (level: $nav{level}). Content:\n$content\n"
    ) unless $nav{is_success};

    decode_entities $_ for values %data;

    $data{content} =~ s/\240/ /g; # fix up &nbsp;s

    $self->content( $data{content} );
    return \%data;
}

1;
__END__

=head1 NAME

WWW::Pastebin::NoMorePastingCom::Retrieve - retrieve pastes from http://nomorepasting.com/ website

=head1 SYNOPSIS

    my $paster = WWW::Pastebin::NoMorePastingCom::Retrieve->new;

    $paster->retrieve('http://www.nomorepasting.com/getpaste.php?pasteid=13350')
        or die $paster->error;

    print "Paste content is:\n$paster\n";

=head1 DESCRIPTION

The module provides interface to retrieve pastes from
L<http://nomorepasting.com/> website via Perl.

=head1 CONSTRUCTOR

=head2 C<new>

    my $paster = WWW::Pastebin::NoMorePastingCom::Retrieve->new;

    my $paster = WWW::Pastebin::NoMorePastingCom::Retrieve->new(
        timeout => 10,
    );

    my $paster = WWW::Pastebin::NoMorePastingCom::Retrieve->new(
        ua => LWP::UserAgent->new(
            timeout => 10,
            agent   => 'PasterUA',
        ),
    );

Constructs and returns a brand new juicy
WWW::Pastebin::NoMorePastingCom::Retrieve
object. Takes two arguments, both are I<optional>. Possible arguments are
as follows:

=head3 C<timeout>

    ->new( timeout => 10 );

B<Optional>. Specifies the C<timeout> argument of L<LWP::UserAgent>'s
constructor, which is used for retrieving. B<Defaults to:> C<30> seconds.

=head3 C<ua>

    ->new( ua => LWP::UserAgent->new( agent => 'Foos!' ) );

B<Optional>. If the C<timeout> argument is not enough for your needs
of mutilating the L<LWP::UserAgent> object used for retrieving, feel free
to specify the C<ua> argument which takes an L<LWP::UserAgent> object
as a value. B<Note:> the C<timeout> argument to the constructor will
not do anything if you specify the C<ua> argument as well. B<Defaults to:>
plain boring default L<LWP::UserAgent> object with C<timeout> argument
set to whatever C<WWW::Pastebin::NoMorePastingCom::Retrieve>'s
C<timeout> argument is
set to as well as C<agent> argument is set to mimic Firefox.

=head1 METHODS

=head2 C<retrieve>

    my $results_ref = $paster->retrieve('http://www.nomorepasting.com/getpaste.php?pasteid=10124')
        or die $paster->error;

    my $results_ref = $paster->retrieve('10124')
        or die $paster->error;

Instructs the object to retrieve a paste specified in the argument. Takes
one mandatory argument which can be either a full URI to the paste you
want to retrieve or just its ID.
On failure returns either C<undef> or an empty list depending on the context
and the reason for the error will be available via C<error()> method.
On success returns a hashref with the following keys/values:

    $VAR1 = {
          'lang' => 'Perl',
          'content' => 'blah blah.. the content of the paste',
    }

=head3 C<lang>

    { 'lang' => 'Perl' }

The C<lang> key will contain the syntax highlighting set for the paste
you are retrieving.

=head3 C<content>

    { 'content' => 'blah blah.. the content of the paste' }

The C<content> key will contain the actual content of your paste.

=head2 C<error>

    $paster->retrieve(10124)
        or die $paster->error;

On failure C<retrieve()> returns either C<undef> or an empty list depending
on the context and the reason for the error will be available via C<error()>
method. Takes no arguments, returns an error message explaining the failure.

=head2 C<id>

    my $paste_id = $paster->id;

Must be called after a successful call to C<retrieve()>. Takes no arguments,
returns a paste ID number of the last retrieved paste irrelevant of whether
an ID or a URI was given to C<retrieve()>

=head2 C<uri>

    my $paste_uri = $paster->uri;

Must be called after a successful call to C<retrieve()>. Takes no arguments,
returns a L<URI> object with the URI pointing to the last retrieved paste
irrelevant of whether an ID or a URI was given to C<retrieve()>

=head2 C<results>

    my $last_results_ref = $paster->results;

Must be called after a successful call to C<retrieve()>. Takes no arguments,
returns the exact same hashref the last call to C<retrieve()> returned.
See C<retrieve()> method for more information.

=head2 C<content>

    my $paste_content = $paster->content;

    print "Paste content is:\n$paster\n";

Must be called after a successful call to C<retrieve()>. Takes no arguments,
returns the actual content of the paste. B<Note:> this method is overloaded
for this module for interpolation. Thus you can simply interpolate the
object in a string to get the contents of the paste.

=head2 C<ua>

    my $old_LWP_UA_obj = $paster->ua;

    $paster->ua( LWP::UserAgent->new( timeout => 10, agent => 'foos' );

Returns a currently used L<LWP::UserAgent> object used for retrieving
pastes. Takes one optional argument which must be an L<LWP::UserAgent>
object, and the object you specify will be used in any subsequent calls
to C<retrieve()>.

=head1 SEE ALSO

L<LWP::UserAgent>, L<URI>

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>
(L<http://zoffix.com>, L<http://haslayout.net>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-pastebin-nomorepastingcom-retrieve at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Pastebin-NoMorePastingCom-Retrieve>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Pastebin::NoMorePastingCom::Retrieve

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Pastebin-NoMorePastingCom-Retrieve>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Pastebin-NoMorePastingCom-Retrieve>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Pastebin-NoMorePastingCom-Retrieve>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Pastebin-NoMorePastingCom-Retrieve>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
