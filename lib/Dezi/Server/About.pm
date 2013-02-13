package Dezi::Server::About;
use strict;
use warnings;
use Carp;
use JSON;
use Search::Tools::XML;
use Scalar::Util qw( blessed );

our $VERSION = '0.002010';

sub new {
    my $class       = shift;
    my %args        = @_;
    my $server      = delete $args{server} or croak "server required";
    my $req         = delete $args{request} or croak "request required";
    my $search_path = delete $args{search_path}
        or croak "search_path required";
    my $index_path = delete $args{index_path} or croak "index_path required";
    my $commit_path = delete $args{commit_path}
        or croak "commit_path required";
    my $rollback_path = delete $args{rollback_path}
        or croak "rollback_path required";
    my $dezi_config = ( delete $args{config} || delete $args{dezi_config} )
        or croak "config required";

    if ( !blessed $dezi_config or !$dezi_config->isa('Dezi::Config') ) {
        croak "config|dezi_config must be a Dezi::Config object";
    }

    my $version    = delete $args{version} || $VERSION;
    my $admin_path = delete $args{admin_path};
    my $ui_path    = delete $args{ui_path};

    if ( $args{require_root} and $req->path ne '/' ) {
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
    my $format
        = lc(  $req->parameters->{t}
            || $req->parameters->{format}
            || $server->engine->default_response_format );

    my ( $search_uri, $index_uri, $commit_uri, $rollback_uri );
    my $uri = delete $args{base_uri} || $req->base;
    $uri =~ s!/$!!;
    if ( $search_path =~ m/^https?:/ ) {
        $search_uri = $search_path;
    }
    else {
        $search_uri = $uri . $search_path;
    }
    if ( $index_path =~ m/^https?:/ ) {
        $index_uri = $index_path;
    }
    else {
        $index_uri = $uri . $index_path;
    }
    if ( $commit_path =~ m/^https?:/ ) {
        $commit_uri = $uri;
    }
    else {
        $commit_uri = $uri . $commit_path;
    }
    if ( $rollback_path =~ m/^https?:/ ) {
        $rollback_uri = $uri;
    }
    else {
        $rollback_uri = $uri . $rollback_path;
    }

    my @methods       = $server->engine->get_allowed_http_methods();
    my $spore_methods = [
        {   method      => 'GET',
            path        => "$search_path",
            params      => [qw( q r c f o s p t u x L )],
            required    => [qw( q )],
            description => 'return search results',
            base_url    => "$search_uri",
        },
        {   method      => 'GET',
            path        => "$search_path" . '/:doc_uri',
            params      => [],
            required    => [],
            description => 'fetch the content for doc_uri',
            base_url    => "$search_uri",
        },
        {   method      => 'GET',
            path        => "$index_path" . '/:doc_uri',
            params      => [],
            required    => [],
            description => 'fetch the content for doc_uri',
            base_url    => "$index_uri",
        },
        {   method      => 'POST',
            path        => "$index_path" . '/:doc_uri',
            params      => [],
            required    => [],
            description => 'update the index with content for doc_uri',
            base_url    => "$index_uri",
        },
        {   method      => 'PUT',
            path        => "$index_path" . '/:doc_uri',
            params      => [],
            required    => [],
            description => 'update the index with content for doc_uri',
            base_url    => "$index_uri",
        },
        {   method      => 'DELETE',
            path        => "$index_path" . '/:doc_uri',
            params      => [],
            required    => [],
            description => 'remove doc_uri from the index',
            base_url    => "$index_uri",
        },
    ];
    if ( grep { $_ eq 'COMMIT' } @methods ) {
        push @$spore_methods,
            {
            method      => 'POST',
            path        => "$commit_path",
            params      => [],
            required    => [],
            description => 'complete any pending updates',
            base_url    => "$commit_uri",
            };
    }
    if ( grep { $_ eq 'ROLLBACK' } @methods ) {
        push @$spore_methods,
            {
            method      => 'POST',
            path        => "$rollback_path",
            params      => [],
            required    => [],
            description => 'abort any pending updates',
            base_url    => "$rollback_uri",
            };
    }

    my $about = {
        name         => 'Dezi',
        author       => 'Peter Karman <karpet@dezi.org>',
        api_base_url => "$uri",
        api_format   => [qw( JSON ExtJS XML Tiny )],
        methods      => $spore_methods,
        engine       => ref( $server->engine ),
        search       => "$search_uri",
        index        => "$index_uri",
        commit       => "$commit_uri",
        rollback     => "$rollback_uri",
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
    if ( $dezi_config->ui ) {
        $about->{ui_class} = ref( $dezi_config->ui );
        $about->{ui}       = $uri . $ui_path;
    }
    if ( $dezi_config->admin ) {
        $about->{admin_class} = $dezi_config->admin_class;
        $about->{admin}       = $uri . $admin_path;
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
    require_root    => 1,   # request must be for /
    server          => $server,
    request         => $plack_request,
    search_path     => $search_path,
    index_path      => $index_path,
    commit_path     => $commit_path,
    rollback_path   => $rollback_path,
    config          => $dezi_config,
    version         => $VERSION,
 );

=head1 DESCRIPTION

Dezi::Server::About allows a Dezi::Server to introspect,
and returns an object describing the server.

The About response is what you get, in JSON format, when you issue
a GET request to the Dezi root path. It allows
client applications to find out details about
the server, including what methods are available
and which URI paths should be used for searching
and indexing.

This class is used internally by Dezi::Server.

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

    perldoc Dezi::Server::About


You can also look for information at:

=over 4

=item * Website

L<http://dezi.org/>

=item * IRC

#dezisearch at freenode

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
