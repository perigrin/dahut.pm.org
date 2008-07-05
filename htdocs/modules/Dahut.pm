package Bot::Pluggable::Dahut;
$VERSION = 0.01;
use strict; 
use warnings;

=pod

=head1 package Bot::Pluggable::Dahut

        DAHUUUTTT!!!

=cut

use base qw(Bot::Pluggable::Common);
use POE;

my @responses = (
    ['tell', '*yarg*'],
    ['tell', 'Yo kids!'],
    ['tell', 'DAAAHUUUUUT!!!!'],
    ['tell', 'DAAAAAHUUUT!'],
    ['tell', 'METADATA!'],
    ['tell', 'Yo kids!'],
    ['tell', 'DAAAAAHUUUUUUT!!'],
    ['tell', 'METADATA!'],
    ['tell', 'Yo kids!'],
    ['tell', 'METADATA!'],
    ['tell', 'DAHUUT!!'],
    ['do', 'hides from the chaotic noise'],
);

sub dahut {
   my ($self, $sender) = @_;
   my ($method, $string)  = @{ $responses[rand @responses] };
		$self->$method($sender, $string);
   return 1;
}

sub told {
    my ($self, $nick, $channel, $message) = @_;
    my $sender = $channel || $nick;
    for ($message) {
        /^d+a+h+u+t+[!?.]*/i && $self->dahut($sender);
    }
}

#
# EVENTS
#

sub irc_public {
    my ($self, $bot, $nickstring, $channels, $message) = @_[OBJECT, SENDER, ARG0, ARG1, ARG2];  
    my $nick = $self->nick($nickstring);
    if ($message =~ /^\s*(\S+)\s*$/) {
        $self->told($nick, $channels->[0], $1);
    }
		 return 0;
}