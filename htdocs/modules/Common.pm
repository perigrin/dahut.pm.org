package Bot::Pluggable::Common;
$VERSION = 0.01;
use strict; 
use warnings;

=pod

=head1 package Bot::Pluggable::Trust

         Common and useful routines for writing Bot::Pluggable Bots

=cut

use POE;

sub new {
    my $class = shift;
    return bless {@_}, ref $class || $class;
}

sub init{
    my ($self, $bot) = @_;
    $self->{_BOT_} = $bot;
}

sub nick {
   my ($self, $nickstring) = @_;
		my ($nick, undef) = split(/!/, $nickstring, 2);
		return $nick;
}

sub tell {
    my ($self, $target, $message) = @_;
    $self->{_BOT_}->privmsg($target, $message) if $target and $message; 
}


#
# EVENTS
#

sub irc_001 {
    my ($self, $bot, $kernel) = @_[OBJECT, SENDER, KERNEL];
		 $self->init($bot);
		 return 0;
}
