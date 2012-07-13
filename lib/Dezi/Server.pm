package Dezi::Server;
use warnings;
use strict;
use Carp;
use Plack::Builder;
use base 'Search::OpenSearch::Server::Plack';
use Dezi::Server::About;

our $VERSION = '0.001006';

sub new {
    my ( $class, %args ) = @_;

    # default engine config
    my $engine_config = $args{engine_config} || {};
    $engine_config->{type}  ||= 'Lucy';
    $engine_config->{index} ||= ['dezi.index'];
    my $search_path = delete $args{search_path};
    $engine_config->{link} ||= 'http://localhost:5000' . $search_path;
    $engine_config->{default_response_format} ||= 'JSON';
    $engine_config->{debug} = $args{debug};
    $args{engine_config} = $engine_config;

    return $class->SUPER::new(%args);
}

sub parse_dezi_config {
    my $class       = shift;
    my $config      = shift or croak "config hashref required";
    my $search_path = delete $config->{search_path} || '/search';
    my $index_path  = delete $config->{index_path} || '/index';
    $search_path = "/$search_path" unless $search_path =~ m!^/!;
    $index_path  = "/$index_path"  unless $index_path  =~ m!^/!;

    my $server = $class->new( %$config, search_path => $search_path );

    my $ui;
    if ( $config->{ui_class} ) {
        $ui = $config->{ui_class}->new( search_path => $search_path );
    }
    my $admin;
    if ( $config->{admin_class} ) {
        $admin = $config->{admin_class}->new( $class, $config );
    }
    return {
        search_path => $search_path,
        index_path  => $index_path,
        server      => $server,
        ui          => $ui,
        admin       => $admin,
    };
}

sub app {
    my ( $class, $config ) = @_;

    my $dezi_config = $class->parse_dezi_config($config);

    return builder {

        enable "SimpleLogger", level => $config->{'debug'} ? "debug" : "warn";

        # right now these are identical
        mount $dezi_config->{search_path} => $dezi_config->{server};
        mount $dezi_config->{index_path}  => $dezi_config->{server};

        if ( $dezi_config->{ui} ) {
            mount '/ui' => $dezi_config->{ui};

            # necessary for Ext callback to work in UI
            enable "JSONP";

            # TODO hack for Ext uri
            mount "/resources/images/default/s.gif" => sub {
                my $req  = Plack::Request->new(shift);
                my $resp = $req->new_response;
                $resp->redirect( 'http://dezi.org/ui/example/s.gif', 301 );
                return $resp->finalize();
                }

        }

        if ( $dezi_config->{admin} ) {
            mount '/admin' => $dezi_config->{admin};
        }

        # default is just self-description
        mount '/' => sub {
            my $req = Plack::Request->new(shift);
            return Dezi::Server::About->new(
                server      => $dezi_config->{server},
                request     => $req,
                search_path => $dezi_config->{search_path},
                index_path  => $dezi_config->{index_path},
                config      => $config,
                version     => $VERSION,
            );
        };

        mount '/favicon.ico' => sub {
            my $req = Plack::Request->new(shift);
            my $res = $req->new_response(301);
            $res->redirect('http://dezi.org/favicon.ico');
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

=head2 parse_dezi_config( I<config> )

Returns hashref of values culled from I<config> including a server instance.
Used internally by app().

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

Copyright 2011 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 SEE ALSO

L<Search::OpenSearch>, L<SWISH::3>, L<SWISH::Prog::Lucy>,
L<Plack>, L<Lucy>

=cut
