package Dezi::Server;
use warnings;
use strict;
use Plack::Builder;
use base 'Search::OpenSearch::Server::Plack';
use JSON;
use Search::Tools::XML;

our $VERSION = '0.001002';

sub new {
    my ( $class, %args ) = @_;

    # default engine config
    my $engine_config = $args{engine_config} || {};
    $engine_config->{type}   ||= 'Lucy';
    $engine_config->{index}  ||= ['dezi.index'];
    $engine_config->{fields} ||= [
        qw(
            swishencoding
            swishmime
            swishdocsize
            )
    ];
    my $search_path = delete $args{search_path};
    $engine_config->{link} ||= 'http://localhost:5000' . $search_path;
    $engine_config->{default_response_format} ||= 'JSON';
    $engine_config->{debug} = $args{debug};
    $args{engine_config} = $engine_config;

    return $class->SUPER::new(%args);
}

sub about {
    my ( $self, $server, $req, $search_path, $index_path ) = @_;

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
        search      => $uri . $search_path,
        index       => $uri . $index_path,
        description => 'This is a Dezi search server.',
        version     => $VERSION,
        fields      => $server->engine->fields,
        facets      => $server->engine->facets,
    };
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

sub app {
    my ( $class, $config ) = @_;

    my $search_path = delete $config->{search_path} || '/search';
    my $index_path  = delete $config->{index_path}  || '/index';
    $search_path = "/$search_path" unless $search_path =~ m!^/!;
    $index_path  = "/$index_path"  unless $index_path  =~ m!^/!;

    my $server = $class->new( %$config, search_path => $search_path );

    return builder {

        enable "SimpleLogger", level => $config->{'debug'} ? "debug" : "warn";

        # right now these are identical
        mount $search_path => $server;
        mount $index_path  => $server;

        # default is just self-description
        mount '/' => sub {
            my $req = Plack::Request->new(shift);
            return $class->about( $server, $req, $search_path, $index_path );
        };

        # TODO /admin
    };

}

1;

__END__

=head1 NAME

Dezi::Server - Dezi Plack server

=head1 SYNOPSIS

Start the Dezi server, listening on port 5000:

 % dezi -p 5000

Add a document B<foo> to the index:

 % curl http://localhost:5000/index/foo -XPOST \
   -d '<doc><title>bar</title>hello world</doc>' \
   -H 'Content-Type: application/xml'
   
Search the index:

 % curl 'http://localhost:5000/search?q=bar&format=json'
 % curl 'http://localhost:5000/search?q=bar&format=xml'

=head1 DESCRIPTION

Dezi is a search platform based on Apache Lucy, Swish3,
Search::OpenSearch and Search::Query. 

Dezi integrates several CPAN search libraries into one
easy-to-use interface.

=head1 METHODS

Dezi::Server is a subclass of Search::OpenSearch::Server::Plack.
It isa Plack::Middleware. Only new methods are overridden.

=head2 new([ engine_config => $config_hashref ])

Returns an instance of the server.

=head2 app( I<opts> )

The Plack::Builder construction, class method. Called within the Plack
server. Override this method in a subclass to change the basic application
definition.

=head2 about( I<server>, I<request>, I<search_path>, I<index_path> )

Returns Plack-ready response describing the Dezi server. Used
by Dezi::Client (among others) for interrogating the server about
service paths, version, etc.

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

Copyright 2011 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 SEE ALSO

L<Search::OpenSearch>, L<SWISH::3>, L<SWISH::Prog::Lucy>,
L<Plack>, L<Lucy>

=cut
