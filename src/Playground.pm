# A damn nice SNAKE clone, code origin by Lars Heppert
# from "Coding for fun mit Python" and translated by
# into 'perl' by me, Thomas Lang, (c) 2016.
#
# Playground that represents the field the snake is gliding on.

package Playground;

use strict;
use warnings;
use Switch;

use lib '.'; # Use library in current directory
use Snake;

sub new {
    my $class = shift;
    my $self = {
        width     => 0,
        height    => 0,
        apples    => [],
        obstacles => [],
        exit_pos  => [],
        snake     => []
    };
    bless $self, $class;
}


# Loads the passed level.
sub loadLevel {
    my ($self, $filename) = @_;

    open(LEVEL, "<" . $filename) or die "Could not open level file '" . $filename . "'.";
    my @lines = <LEVEL>;
    close(LEVEL);

    my $x;
    my $y = -1;
    my $sy = 0;

    foreach my $line (@lines) {
        $y++;
        $x = -1;
        foreach my $char (split //, $line) {
            if ($char ne "\n") {
                $x++;

                switch($char) {
                    case "A" { push    @{$self->{apples   }}, ($x, $y); }
                    case "s" { push    @{$self->{snake    }}, ($x, $y); }
                    case "S" { unshift @{$self->{snake    }}, ($x, $y); }
                    case "H" { push    @{$self->{obstacles}}, ($x, $y); }
                    case "E" { push    @{$self->{exit_pos }}, ($x, $y); }
                }
            }
        }
    }

    $self->{width} = $x; $self->{height} = $y;
}


# Colision detection, distinctive handling by object type.
sub collision_detection {
    my ($self, $x, $y) = @_;

    # Helper functions, self explaining.
    sub contains {
        my ($a, $b, @arr) = @_;
        my $contains = 0;

        foreach my $i (0 .. ((scalar(@arr)/2)-1)) {
            if ($arr[2*$i] eq $a && $arr[2*$i+1] eq $b) { $contains = 1; last; }
        }

        $contains
    }

    sub remove {
        my ($a, $b, @arr) = @_;
        my @out;

        foreach my $i (0 .. ((scalar(@arr)/2)-1)) {
            if (!($arr[2*$i] eq $a && $arr[2*$i+1] eq $b)) { push @out, $arr[2*$i]; push @out, $arr[2*$i+1]; }
        }
        
        @out;
    }

    my $_col;

    if    (contains($x, $y, @{$self->{snake}    })) { $_col = Snake::COLLISION; }
    elsif (contains($x, $y, @{$self->{obstacles}})) { $_col = Snake::COLLISION; }
    elsif (contains($x, $y, @{$self->{apples}   })) { 
        @{$self->{apples}} = remove($x, $y, @{$self->{apples}}); # Remove eaten apple.
        $_col = Snake::EAT_APPLE;
    }
    elsif (contains($x, $y, @{$self->{exit_pos }})) { $_col = Snake::PASS_EXIT;    }
    else                                            { $_col = Snake::NO_COLLISION; }

    return $_col;
}


1;
