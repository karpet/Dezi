package Dezi::Server;
use Moose;
extends 'Search::OpenSearch::Server::Plack';
use Carp;
use Plack::Builder;
use Dezi::Server::About;
use Dezi::Config;
use Scalar::Util qw( blessed );

our $VERSION = '0.002999_01';

sub app {
    my ( $class, $config ) = @_;

    my $dezi_config;
    if ( blessed $config) {
        $dezi_config = $config;
    }
    else {
        $dezi_config
            = Dezi::Config->new( { %$config, server_class => $class } );
    }

    return builder {

        enable "SimpleLogger",
            level => $dezi_config->debug ? "debug" : "warn";

        enable_if { $_[0]->{REMOTE_ADDR} eq '127.0.0.1' }
        "Plack::Middleware::ReverseProxy";

        mount $dezi_config->search_path() =>
            $dezi_config->search_server->to_app;
        mount $dezi_config->index_path() => builder {
            if ( defined $dezi_config->authenticator ) {
                enable "Auth::Basic",
                    authenticator => $dezi_config->authenticator,
                    realm         => 'Dezi Indexer';
            }
            $dezi_config->index_server->to_app;
        };
        mount $dezi_config->commit_path() => builder {
            if ( defined $dezi_config->authenticator ) {
                enable "Auth::Basic",
                    authenticator => $dezi_config->authenticator,
                    realm         => 'Dezi Indexer';
            }
            sub {
                my $env = shift;
                if ( $env->{REQUEST_METHOD} eq 'POST' ) {
                    $env->{REQUEST_METHOD} = 'COMMIT';
                }
                $dezi_config->index_server->call($env);
            };
        };
        mount $dezi_config->rollback_path() => builder {
            if ( defined $dezi_config->authenticator ) {
                enable "Auth::Basic",
                    authenticator => $dezi_config->authenticator,
                    realm         => 'Dezi Indexer';
            }
            sub {
                my $env = shift;
                if ( $env->{REQUEST_METHOD} eq 'POST' ) {
                    $env->{REQUEST_METHOD} = 'ROLLBACK';
                }
                $dezi_config->index_server->call($env);
            };
        };

        if ( $dezi_config->ui ) {
            mount $dezi_config->ui_path() => $dezi_config->ui->to_app;
        }

        if ( $dezi_config->admin ) {
            mount $dezi_config->admin_path() => $dezi_config->admin;
        }

        # default is just self-description
        mount '/' => sub {
            my $req = Plack::Request->new(shift);
            return Dezi::Server::About->new(
                require_root  => 1,
                server        => $dezi_config->index_server,
                request       => $req,
                search_path   => $dezi_config->search_path,
                index_path    => $dezi_config->index_path,
                commit_path   => $dezi_config->commit_path,
                rollback_path => $dezi_config->rollback_path,
                admin_path    => $dezi_config->admin_path,
                ui_path       => $dezi_config->ui_path,
                config        => $dezi_config,
                version       => $VERSION,
                base_uri      => $dezi_config->base_uri,
            );
        };

        mount '/favicon.ico' => sub {
            my $req = Plack::Request->new(shift);
            my $res = $req->new_response();
            $res->redirect( 'http://dezi.org/favicon.ico', 301 );
            $res->finalize();
        };

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

 % curl 'http://localhost:5000/search?q=bar&t=JSON'
 % curl 'http://localhost:5000/search?q=bar&t=XML'

=head1 DESCRIPTION

Dezi is a search platform based on Apache Lucy, Swish3,
Search::OpenSearch and Search::Query. 

Dezi integrates several CPAN search libraries into one
easy-to-use interface.

Be sure to read the perldoc for L<Search::OpenSearch::Engine>
and L<Search::OpenSearch::Server::Plack>.

=head1 METHODS

Dezi::Server is a subclass of L<Search::OpenSearch::Server::Plack>.
Only new methods are overridden.

=head2 app( I<config> )

Class method that uses L<Plack::Builder> to construct the server
application. I<config> should be a hashref that is converted
internally to a L<Dezi::Config> object.

Returns the Plack $app via the L<Plack::Builder> builder() function.

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dezi at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dezi>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dezi::Server


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

Copyright 2011 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 SEE ALSO

L<Search::OpenSearch>, L<SWISH::3>, L<SWISH::Prog::Lucy>,
L<Plack>, L<Lucy>

=cut
