#!/usr/bin/perl
#
# A damn nice SNAKE clone, code origin by Lars Heppert
# from "Coding for fun mit Python" and translated by
# into 'perl' by me, Thomas Lang, (c) 2016.
#
# Main module.
package main;

use strict;
use warnings;
use OpenGL qw/ :all/;
use Switch;

use lib 'src';
use Snake;
use Playground;
use SnakeConfig;

# Configuration
my $config = SnakeConfig::snake_config;
my $LIVING_SPACE_WIDTH  = $config->{"LIVING_SPACE_WIDTH"};
my $LIVING_SPACE_HEIGHT = $config->{"LIVING_SPACE_HEIGHT"};
my $CELL_SIZE           = $config->{"CELL_SIZE"};
my $TITLE               = $config->{"TITLE"};
my $MAXIMUM_LEVEL_INDEX = $config->{"MAXIMUM_LEVEL_INDEX"};
my $MAXIMUM_TRIES       = $config->{"MAXIMUM_TRIES"};
my $DELAY               = $config->{"DELAY"};
my $GAME_OVER_DELAY     = $config->{"GAME_OVER_DELAY"};

#-------------------------------------------------------------------
# Implementation
#
my $WINDOW_WIDTH  = $LIVING_SPACE_WIDTH  * $CELL_SIZE;
my $WINDOW_HEIGHT = $LIVING_SPACE_HEIGHT * $CELL_SIZE;

use constant OBSTACKLE_COLOR    => (0.5, 0.5, 0.5, 1.0); # obstacles are  grey
use constant SNAKE_COLOR        => (0.0, 1.0, 0.0, 1.0); # the snake is   gree
use constant APPLE_COLOR        => (1.0, 0.0, 0.0, 1.0); # apples    are  red 
use constant EXIT_COLOR         => (0.0, 0.0, 1.0, 1.0); # the exit  is   blue
use constant GROUND_COLOR       => (0.0, 0.0, 0.0, 1.0); # otherwise it's blac

# resources
use constant LEVEL_DIR          => "./Levels/";
use constant ASCII_ART_DIR      => "./res/";
use constant GAME_OVER_SCREEN   => ASCII_ART_DIR . "GameOver.txt";
use constant YOU_WON_SCREEN     => ASCII_ART_DIR . "YouWon.txt";
use constant NO_MORE_LVL_SCREEN => ASCII_ART_DIR . "NoMoreLevels.txt";

# Variables.
my $playground    = Playground->new;         # The area the game takes place.
my $snake         = Snake->new($playground); # The snake ^^
my @direction     = (0, 0);                  # Direction to move to.
my @commands;                                # Command queue.
my $cur_lvl_idx   = 0;                       # Index of the current level.
my $current_tries = 1;                       # Amount of tries taken for the current level.
my $global_score  = 0;                       # Global score.


# Gets the level file name, e.g. "Level1".
sub getLevelName {
    my ($idx) = @_;
    return LEVEL_DIR . "Level" . $idx;
}

# Restarts the game, including loading the (new) level.
sub restart_game {
    my $score = shift // 0;
    glFinish;
    $playground = Playground->new;
    $snake      = Snake->new($playground, $score);
    @direction  = (0, 0);
    @commands   = ();
    $playground->loadLevel(getLevelName($cur_lvl_idx));
}

# Handle keyboard input (Arrow keys).
sub kbd {
    my ($key) = @_;

    switch ($key) {
        # First and only cheat in this game:
        # hop to level 4 (or the last level) immediately
        case 27 { # ESC key
            $cur_lvl_idx = 4 <= $MAXIMUM_LEVEL_INDEX ? 4 : $MAXIMUM_LEVEL_INDEX;
            restart_game;
        }
        case GLUT_KEY_UP    { push @commands, ( 0, -1); }
        case GLUT_KEY_DOWN  { push @commands, ( 0,  1); }
        case GLUT_KEY_LEFT  { push @commands, (-1,  0); }
        case GLUT_KEY_RIGHT { push @commands, ( 1,  0); }
    }
}

my $OFF = $CELL_SIZE - 1.0;

# Displays an ASCII art consisting of 'X's on the screen.
# This does NOT check for boundary safety!
sub show_ascii_art {
    my ($filename, $delay) = @_;
    
    open(LEVEL, "<" . $filename) or die "Could not open file '" . $filename . "'.";
    my @lines = <LEVEL>;
    close(LEVEL);
    
    my $x;
    my $y = -1;
    my $sy = 0;
    my @ascii_art;
    
    foreach my $line (@lines) {
        $y++; $x = -1;
        foreach my $char (split //, $line) {
            if ($char ne "\n") {
                $x++;
                if ($char eq "X") { push @ascii_art, ($x, $y); }
            }
        }
    }
    
    clear_screen();
    draw_element(\@ascii_art, [APPLE_COLOR]);
    glutSwapBuffers;
    sleep($GAME_OVER_DELAY);
}

# Prints the score in bold green on the console.
sub show_score {
    print "Your score: \033[1;32m $global_score\033[0m\n";
}

# Show 'Game over' screen, pause and restart level.
sub show_game_over {
    show_ascii_art(GAME_OVER_SCREEN, $GAME_OVER_DELAY);
    $current_tries++;

    if ($current_tries > $MAXIMUM_TRIES) {
        $global_score += $snake->get_score;
        print "You've taken too much tries, stupid!\n";
        show_score;
        exit 0;
    } else { restart_game; }
}

# Show 'You won' screen, pause and start next level.
sub show_you_won {
    show_ascii_art(YOU_WON_SCREEN, $GAME_OVER_DELAY);
    $cur_lvl_idx++;
    $current_tries = 1;
    $global_score += $snake->get_score;
    
    if ($cur_lvl_idx > $MAXIMUM_LEVEL_INDEX) {
        print "Congratulations, you completed all levels!\n";
        show_score;
        exit 0;
    } else {
        restart_game($snake->get_score);
    }
}

# Draws the passed element in the passed color.
sub draw_element {
    my ($element_ref, $color_ref) = @_; # array references
    
    my @element = @$element_ref;
    my $size = scalar(@element)/2;
    glColor4f(@$color_ref);

    glBegin(GL_QUADS);
    for my $i (0 .. ($size-1)) {
        my ($x, $y) = ($element[2*$i] * $CELL_SIZE, $element[2*$i+1] * $CELL_SIZE);
        glVertex3f($x       , $y       , 0.0);
        glVertex3f($x + $OFF, $y       , 0.0);
        glVertex3f($x + $OFF, $y + $OFF, 0.0);
        glVertex3f($x       , $y + $OFF, 0.0);
    }
    glEnd;
}

# Well, clears the screen ^^
sub clear_screen {
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glLoadIdentity();
    glTranslatef(0.0, 0.0, 3.0);
}


my $game_cycle = 0;

sub draw {
    # Draw only every four times, will make the thing a bit nicer.
    $game_cycle++;
    $game_cycle %= 4;
    
    if (@commands) {
        my $valid_cmd = 0;
        my ($new_x, $new_y) = ($commands[0], $commands[1]);

        while (!$valid_cmd && @commands) {
            my ($new_x, $new_y) = (shift @commands, shift @commands);
            my ($old_x, $old_y) = @direction;

            # Do not allow 180 degrees turnover.
            if (!((abs($new_x) == abs($old_x)) && (abs($new_y) == abs($old_y)))) {
                $valid_cmd = 1;
                last;
            }
        }

        if ($valid_cmd) { @direction = ($new_x, $new_y); }
    }
    
    if ($game_cycle == 0) {
        if ($direction[0] != 0 || $direction[1] != 0) {
            my $_coll = $snake->move(@direction);
            
            if    ($_coll eq Snake::COLLISION) { show_game_over; } 
            elsif ($_coll eq Snake::PASS_EXIT) {
                # You have only won if you ate up all apples.
                show_you_won if (!(@{$playground->{apples}})); 
            }
        }
        
        clear_screen;
        draw_element(\@{$playground->{obstacles}}, [OBSTACKLE_COLOR]);
        draw_element(\@{$playground->{apples}},    [APPLE_COLOR    ]);
        draw_element(\@{$playground->{snake}},     [SNAKE_COLOR    ]);
        
        # Draw exit iff all apples are eaten up.
        if (!@{$playground->{apples}}) {
            draw_element(\@{$playground->{exit_pos}},  [EXIT_COLOR]);
        }
        
        glutSwapBuffers;
        glutPostRedisplay;
    }
}

sub resize {
    my ($width, $height) = @_;
    if ($height == 0) { $height = 1; }

    glViewport(0, 0, $width, $height);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();           

    glOrtho(-$CELL_SIZE, 
             $WINDOW_WIDTH  + $CELL_SIZE, 
             $WINDOW_HEIGHT + $CELL_SIZE, 
            -$CELL_SIZE, 
            -6.0, 
             0.0);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
}

sub init {
    glClearColor(0.0, 0.0, 0.0, 0.0);
}

# Timer callback, simply forces redrawing.
sub timer {
    glutPostRedisplay;
    glutTimerFunc($DELAY, \&timer, 0);
}

#-----------------------------------------------------------

# Main entry point
glutInit;
glutInitWindowSize($WINDOW_WIDTH, $WINDOW_HEIGHT);
glutInitWindowPosition(180, 80); # nice positioning on my 13" notebook
glutCreateWindow($TITLE);
resize($WINDOW_WIDTH, $WINDOW_HEIGHT);
init;

$playground->loadLevel(getLevelName($cur_lvl_idx));

glutDisplayFunc(\&draw);
glutSpecialFunc(\&kbd);
glutKeyboardFunc(\&kbd);
glutTimerFunc($DELAY, \&timer, 0);
glutMainLoop;
