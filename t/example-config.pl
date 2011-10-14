# example Dezi server config file, in Perl format
# Dezi uses Config::Any, so any format supported by
# that module should work as well.

use CHI;

my $c = {

    engine_config => {

        # name of the index(es)
        index => [qw( t/test.index )],

        # which facets to calculate, and how many results to consider
        facets => {
            names       => [qw( color size flavor )],
            sample_size => 10_000,
        },

        # result attributes in response
        fields => [qw( color size flavor )],

        # options passed to SWISH::Prog::Lucy::Indexer->new
        indexer_config => {
            config => { 

                # searchable fields
                MetaNames => 'color size flavor',

                # attributes to store
                PropertyNames => 'color size flavor',

                # auto-vivify new fields based on POSTed docs
                UndefinedMetaTags => 'auto',

                # treat unknown mime types as text/plain
                DefaultContents => 'TXT',

                # use English snowball stemmer
                FuzzyIndexingMode => 'Stemming_en1',

            }, 

            # store token positions to optimize snippet creation
            highlightable_fields => 1,
        },

        # options passed to SWISH::Prog::Lucy::Searcher->new
        searcher_config => {
            max_hits             => 1000,
            find_relevant_fields => 1,
        },

        # cache facets for speed-up
        cache => CHI->new(
            driver           => 'File',
            dir_create_mode  => 0770,
            file_create_mode => 0660,
            root_dir         => "/tmp/opensearch_cache",
        ),
        cache_ttl => 3600,

        # explicitly turn off highlighting for some fields
        do_not_hilite => [qw( color )],

        # see Search::Tools::Snipper
        snipper_config => { as_sentences => 1 },

        # see Search::Tools::HiLiter
        hiliter_config => { class => 'h', tag => 'b' },

        # see Search::Query::Parser
        parser_config => {},

    }
};
