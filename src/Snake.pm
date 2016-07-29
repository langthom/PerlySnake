# A damn nice SNAKE clone, code origin by Lars Heppert
# from "Coding for fun mit Python" and translated by
# into 'perl' by me, Thomas Lang, (c) 2016.
#
# Snake module representing - well, what else? - the snake.

package Snake;

use strict;
use warnings;

use lib '.';
use SnakeConfig;

# Internal constants defining different types of collisions.
use constant NO_COLLISION =>  0;
use constant COLLISION    => -1;
use constant EAT_APPLE    => -2;
use constant PASS_EXIT    => -3;

my $config = SnakeConfig::snake_config;
# How many points on score per apple?
my $POINTS_PER_APPLE = $config->{"POINTS_PER_APPLE"};
my $APPLE_EXPANSION  = $config->{"APPLE_EXPANSION"};

sub new {
    my $class = shift;
    my $self = {
        _playground => shift,
        _expansion  => 0,
        _score      => shift // 0
    };
    bless $self, $class;
}

# Move the snake in the direction (x, y).
sub move {
    my ($self, $dx, $dy) = @_;

    my $plgr = $self->{_playground};
    my @snake = @{$plgr->{snake}};
    my ($head_x, $head_y) = ($snake[0], $snake[1]);
    my @newHead = ($head_x + $dx, $head_y + $dy);

    my $_coll = $plgr->collision_detection(@newHead);
    
    if ($_coll eq EAT_APPLE) {
        $self->{_expansion} += $APPLE_EXPANSION;
        $self->{_score} += $POINTS_PER_APPLE;
    }
    
    unshift @{$plgr->{snake}}, @newHead;

    if ($self->{_expansion} == 0) {
        pop @{$plgr->{snake}}; pop @{$plgr->{snake}};
    } else {
        $self->{_expansion}--;
    }

    $_coll;
}

sub get_score {
    my ($self) = @_;
    return $self->{_score}; 
}

1;
