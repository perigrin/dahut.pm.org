#!/usr/local/bin/perl 

eval 'exec /usr/bin/perl5.8.3  -S $0 ${1+"$@"}'
    if 0; # not running under some shell

use warnings;
use strict;
use lib qw(/var/www/sites/saintpaul.openguides.org/lib);
use CGI;
use OpenGuides::Config;
use OpenGuides::Search;

my $config_file = $ENV{OPENGUIDES_CONFIG_FILE} || "wiki.conf";
my $config = OpenGuides::Config->new( file => $config_file );
my $search = OpenGuides::Search->new( config => $config );
my %vars = CGI::Vars();
$search->run( vars => \%vars );
