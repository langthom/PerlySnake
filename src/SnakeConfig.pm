# A damn nice SNAKE clone, code origin by Lars Heppert
# from "Coding for fun mit Python" and translated by
# into 'perl' by me, Thomas Lang, (c) 2016.
#
# Configuration module.

package SnakeConfig;

use strict;
use warnings;
use AppConfig qw(:expand :argcount);

use constant CONFIG_FILE => "snake.cfg";  # configuration name.

my @config_vars = qw{
LIVING_SPACE_WIDTH
LIVING_SPACE_HEIGHT
CELL_SIZE
TITLE
MAXIMUM_LEVEL_INDEX
MAXIMUM_TRIES
POINTS_PER_APPLE
DELAY
GAME_OVER_DELAY
};

# Global configuration for all variables.
my $conf = AppConfig->new({
    CASE         => 1,            # case-sensitivity
    PEDANTIC     => 1,            # parse error throws exception
    GLOBAL       => {
        ARGCOUNT => ARGCOUNT_ONE, # always one argument expected
        EXPAND   => EXPAND_NONE   # expand nothing
    },}, @config_vars);

$conf->file(CONFIG_FILE);         # read from file

my %config = map { $_ => $conf->get($_) } @config_vars;

# make accessible from outside
sub snake_config { return \%config; }

1;
