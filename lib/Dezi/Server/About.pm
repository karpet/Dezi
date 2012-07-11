package Dezi::Server::About;
use strict;
use warnings;
use Carp;
use JSON;
use Search::Tools::XML;

our $VERSION = '0.001005';

sub new {
    my $class       = shift;
    my %args        = @_;
    my $server      = delete $args{server} or croak "server required";
    my $req         = delete $args{request} or croak "request required";
    my $search_path = delete $args{search_path}
        or croak "search_path required";
    my $index_path = delete $args{index_path} or croak "index_path required";
    my $config     = delete $args{config}     or croak "config required";
    my $version = delete $args{version} || $VERSION;

    if ( $req->path ne '/' ) {
        my $resp = 'Resource not found';
        return [
            404,
            [   'Content-Type'   => 'text/plain',
                'Content-Length' => length $resp,
            ],
            [$resp]
        ];
    }
    $server->setup_engine();
    my $format = lc( $req->parameters->{format}
            || $server->engine->default_response_format );

    my $uri = $req->uri;
    $uri =~ s!/$!!;

    my $about = {
        engine => ref( $server->engine ),
        search => $uri . $search_path,
        index  => $uri . $index_path,
        description =>
            'This is a Dezi search server. See http://dezi.org/ for more details.',
        version => $version,
        fields  => $server->engine->fields,
        facets  => (
              $server->engine->facets
            ? $server->engine->facets->names
            : undef
        ),
    };
    if ( $config->{ui_class} ) {
        $about->{ui} = $config->{ui_class};
    }
    if ( $config->{admin_class} ) {
        $about->{admin} = $config->{admin_class};
    }
    my $resp
        = $format eq 'json'
        ? to_json($about)
        : Search::Tools::XML->perl_to_xml( $about, 'dezi', 1 );
    return [
        200,
        [   'Content-Type'   => 'application/' . $format,
            'Content-Length' => length $resp,
        ],
        [$resp],
    ];
}

1;

__END__

=head1 NAME

Dezi::Server::About - Dezi server introspection metadata

=head1 SYNOPSIS

 my $resp = Dezi::Server::About->new(
                server      => $server,
                request     => $plack_request,
                search_path => $search_path,
                index_path  => $index_path,
                config      => $config,
                version     => $VERSION,
            );

=head1 DESCRIPTION

Dezi::Server::About allows a Dezi::Server to introspect,
and returns an object describing the server.

This class is used internally Dezi::Server.

=head1 METHODS

=head2 new( %args )

See the SYNOPSIS for a description of %args.

Returns an array ref suitable for use as a Plack::Response.

=cut

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dezi at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dezi>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dezi


You can also look for information at:

=over 4

=item * Mailing list

L<https://groups.google.com/forum/#!forum/dezi-search>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dezi>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dezi>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dezi>

=item * Search CPAN

L<http://search.cpan.org/dist/Dezi/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2012 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 SEE ALSO

L<Search::OpenSearch>, L<SWISH::3>, L<SWISH::Prog::Lucy>,
L<Plack>, L<Lucy>

=cut
