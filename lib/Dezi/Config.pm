package Dezi::Config;
use strict;
use warnings;
use Carp;
use Module::Load;
use Plack::Util::Accessor qw(
    search_path
    index_path
    commit_path
    rollback_path
    ui_path
    admin_path
    ui
    admin
    admin_class
    debug
    base_uri
    search_server
    index_server
    authenticator
);

our $VERSION = '0.002011';

sub new {
    my $class         = shift;
    my $config        = shift or croak "config hashref required";
    my $server_class  = delete $config->{server_class} || 'Dezi::Server';
    my $search_path   = delete $config->{search_path} || '/search';
    my $index_path    = delete $config->{index_path} || '/index';
    my $commit_path   = delete $config->{commit_path} || '/commit';
    my $rollback_path = delete $config->{rollback_path} || '/rollback';
    my $ui_path       = delete $config->{ui_path} || '/ui';
    my $admin_path    = delete $config->{admin_path} || '/admin';
    my $username      = delete $config->{username};
    my $password      = delete $config->{password};

    for (
        (   $search_path,   $index_path, $commit_path,
            $rollback_path, $ui_path,    $admin_path,
        )
        )
    {
        $_ = "/$_" unless m!^/!;
    }

    my $base_uri = delete $config->{base_uri} || '';

    my $ui;
    if ( $config->{ui_class} ) {
        load $config->{ui_class};
        $ui = $config->{ui_class}
            ->new( search_path => $search_path, base_uri => $base_uri );
    }

    load $server_class;
    my $search_server = $server_class->new(
        %$config,
        engine_config => $class->apply_default_engine_config(
            { %$config, search_path => $search_path }
        ),
        http_allow => [qw( GET )],
    );
    my $index_server = $server_class->new(
        %$config,
        engine_config => $class->apply_default_engine_config(
            { %$config, search_path => $search_path }
        ),
    );

    my $admin;
    if ( $config->{admin_class} ) {
        load $config->{admin_class};
        $admin = $config->{admin_class}->app(
            user_config => $config,
            searcher    => $search_server,
            base_uri    => $base_uri,
        );
    }

    return bless {
        search_path   => $search_path,
        index_path    => $index_path,
        commit_path   => $commit_path,
        rollback_path => $rollback_path,
        ui_path       => $ui_path,
        admin_path    => $admin_path,
        ui            => $ui,
        admin         => $admin,
        admin_class   => $config->{admin_class},
        base_uri      => $base_uri,
        search_server => $search_server,
        index_server  => $index_server,
        debug         => ( $config->{debug} || $ENV{DEZI_DEBUG} ),
        authenticator => (
            ( defined $username and defined $password )
            ? sub {
                my ( $u, $p ) = @_;
                return $u eq $username && $p eq $password;
                }
            : undef,
        ),
    }, $class;
}

sub apply_default_engine_config {
    my ( $class, $args ) = @_;
    my $engine_config = $args->{engine_config} || {};
    $engine_config->{type}  ||= 'Lucy';
    $engine_config->{index} ||= ['dezi.index'];
    my $search_path = delete $args->{search_path};
    $engine_config->{link} ||= $search_path;
    $engine_config->{default_response_format} ||= 'JSON';
    $engine_config->{debug} = $args->{debug} || $ENV{DEZI_DEBUG};
    return $engine_config;
}

sub as_hash {
    my $self = shift;
    return %$self;
}

1;

__END__

=pod

=head1 NAME

Dezi::Config - Dezi server configuration

=head1 SYNOPSIS

 use Dezi::Config;
 use CHI;
 my $dezi_config = Dezi::Config({
 
    search_path     => '/search',
    index_path      => '/index',
    commit_path     => '/commit',
    rollback_path   => '/rollback',
    ui_path         => '/ui',
    admin_path      => '/admin',
    ui_class        => 'Dezi::UI',
    # or
    # ui              => Dezi::UI->new()
    
    # NOT YET SUPPORTED
    #admin_class     => 'Dezi::Admin',
    #admin           => Dezi::Admin->new(),
    
    base_uri        => '',
    server_class    => 'Dezi::Server',
    
    # authentication for non-idempotent requests.
    # if both username && password are defined,
    # then /index, /commit and /rollback require
    # basic authentication credentials.
    username        => 'someone',
    password        => 'somesecret',
    
    # optional
    # see Dezi::Stats
    stats_logger => Dezi::Stats->new(
        type        => 'DBI',
        dsn         => 'DBI::mysql:database=mydb;host=localhost;port=3306',
        username    => 'myuser',
        password    => 'mysecret',
    ),
    
    # see Search::OpenSearch::Engine
    engine_config => {

        default_response_format => 'JSON',
        
        # could be any Search::OpenSearch::Engine::* class
        type    => 'Lucy',

        # name of the index(es)
        index   => [qw( path/to/your.index )],

        # which facets to calculate, and how many results to consider
        facets => {
            names       => [qw( color size flavor )],
            sample_size => 10_000,
        },

        # result attributes in response
        fields => [qw( color size flavor )],

        # options passed to indexer defined by Engine type (above)
        # defaults to SWISH::Prog::Lucy::Indexer->new
        indexer_config => {
        
            # see SWISH::Prog::Config
            # and http://swish-e.org/docs/swish-config.html
            config => { 

                # searchable fields
                MetaNames => 'color size flavor',

                # attributes to store
                PropertyNames => 'color size flavor',

                # auto-vivify new fields based on POSTed docs.
                # use this if you want ElasticSearch-like effect.
                UndefinedMetaTags => 'auto',

                # treat unknown mime types as text/plain
                DefaultContents => 'TXT',

                # use English snowball stemmer
                FuzzyIndexingMode => 'Stemming_en1',

            }, 

            # store token positions to optimize snippet creation
            highlightable_fields => 1,
        },

        # options passed to searcher defined by Engine type (above)
        # defaults to SWISH::Prog::Lucy::Searcher->new
        searcher_config => {
            max_hits             => 1000,
            find_relevant_fields => 1,
            qp_config => {
                dialect   => 'Lucy',
                null_term => 'NULL',
                # see Search::Query::Parser and Search::Query::Dialect::Lucy
                # for full list of options
            },
        },

        # see LucyX::Suggester
        suggester_config => {
            limit  => 10,
            fields => [qw( color size )],

            # passed to Search::Tools::Spellcheck->new
            # along with parser_config
            spellcheck_config => {
                lang => 'en_US',
            },
        },

        # cache facets for speed-up.
        # this is the Search::OpenSearch default setting
        cache => CHI->new(
            driver           => 'File',
            dir_create_mode  => 0770,
            file_create_mode => 0660,
            root_dir         => "/tmp/opensearch_cache",
        ),
        
        # how long should the facet cache live
        # each cache entry is per-unique-query
        cache_ttl => 3600,

        # explicitly turn off highlighting for some fields
        do_not_hilite => { color => 1 },

        # see Search::Tools::Snipper
        snipper_config => { as_sentences => 1, strip_markup => 1, },

        # see Search::Tools::HiLiter
        hiliter_config => { class => 'h', tag => 'b' },

        # see Search::Tools::QueryParser
        parser_config => {},

    }
 
 });
 
=head1 DESCRIPTION

Dezi::Config parses configuration settings, applies default values,
and instantiates component objects for L<Dezi::Server>. 

Mostly this class exists in order to document, in one location, 
all the options available for the Dezi server. 
You will rarely use Dezi::Config directly; it is intended
as an internal class for use by Dezi::Server. Instead, your C<dezi_config.pl> file
contents are parsed by Dezi::Config and applied to the server application.

The SYNOPSIS section provides all the default configuration values,
with comments indicating where more complete documentation may
be available for the relevant components. The rest of the documentation
below is specific to this class and probably B<not> what you're looking for
as a Dezi user.

=head1 METHODS

=head2 new( I<hashref> )

See the SYNOPSIS for a complete description of the keys/values supported
in I<hashref>.

The following I<hashref> keys are also supported as accessor/mutator
methods on the object returned from new():

    search_path
    index_path
    commit_path
    rollback_path
    ui_path
    admin_path
    ui
    admin
    debug
    base_uri
    search_server
    index_server

=head2 apply_default_engine_config( I<hashref> )

Default L<Search::OpenSearch::Engine> options are applied directly to I<hashref>.
This method is called internally by new().

=head2 authenticator

If I<username> and I<password> are passed to new(),
the authenticator() method will return a CODE ref for passing
to L<Plack::Middleware::Auth::Basic>.

=head2 as_hash

Returns the object as a plain Perl hash of key/value pairs.

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dezi at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dezi>.  
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dezi::Config


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

L<Search::OpenSearch>, L<Search::Tools>, L<SWISH::3>, L<SWISH::Prog::Lucy>,
L<Plack>, L<Lucy>

=cut
