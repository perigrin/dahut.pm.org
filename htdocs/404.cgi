#!/usr/local/bin/perl
use strict;
use warnings;
use CGI qw(:standard);
use CGI::Carp qw(croak fatalsToBrowser);
use lib qw(/var/www/sites/saintpaul.openguides.org/lib);
use OpenGuides;
use OpenGuides::Config;
use OpenGuides::Template;

my $config_file = $ENV{OPENGUIDES_CONFIG_FILE} || "wiki.conf";
my $config = OpenGuides::Config->new( file => $config_file );

my $guide = OpenGuides->new( config => $config );
my $wiki = $guide->wiki;

my $node_name = $ENV{REDIRECT_URL};
$node_name =~ s/\/(?:id=)?//;
my $page_name = $node_name;
$page_name =~ y/_/ /;
my $URL = url();

my %output_conf = ( 
    wiki     => $wiki,
    config   => $config,
    node     => $page_name,
    template => '404.tt',
    vars     => { full_url => $URL },
);

print OpenGuides::Template->output( %output_conf );

