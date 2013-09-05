#!/usr/bin/perl

=head1 NAME

test.pl

=head1 SYNOPSYS

test.pl [options]

  Options:
    --fill                  Fill DB

    --level=DEEPLEVEL       With --fill flag will fill DB with data deep
                            up to DEEPLEVEL level. If --fill flag is omitted,
                            then select data with desired DEEPLEVEL level.
                            Default: 3

=head1 INSTALL

1. Install db:
    %> psql < sql/db.sql

2. Run script :)

=cut

use v5.14;

use strict;
use warnings;

use Data::Dumper;
use Getopt::Long;

use FindBin;
use lib $FindBin::Bin . '/lib';

use Schema;

my $fill;
my $level;

GetOptions(
    "fill!"   => \$fill,
    "level=i" => \$level,
);

$level ||= 3;

my $schema = Schema->connect(
    {
        dsn           => 'dbi:Pg:dbname=dbic_test',
        user          => 'ipfreely',
        password      => '',
        AutoCommit    => 1,
        on_connect_do => q{SET TIME ZONE UTC},
    }
);

if ($fill) {
    $schema->resultset('Category')->delete;
    $schema->storage->dbh->do(
        'ALTER SEQUENCE "categories_id_seq" RESTART WITH 1;');

    fill_categories( 3, $level );
}

my $category      = $schema->resultset('Category')->find(1);
my $subcategories = [ $category->categories->descendants($level)->all ];
$category->related_resultset('categories')->set_cache($subcategories);
print_categories( $category, 0 );

sub print_categories {
    my $level      = pop(@_);
    my @categories = @_;

    for my $category (@categories) {
        say "\t" x $level . $category->title;
        if ( my $subcategories
            = $category->related_resultset('categories')->get_cache )
        {
            print_categories( @{$subcategories}, $level + 1 );
        }
    }
}

sub fill_categories {
    my ( $count, $level, $parent ) = @_;

    return if $level < 0;

    my @position = ( 0 .. $count );
    for my $idx ( 0 .. $count ) {
        my $position = $idx;

        #my $position = splice( @position, rand(@position), 1 ); # random

        my $category
            = ( $parent ? $parent->categories : $schema->resultset('Category') )
            ->create(
            {
                title => 'Category '
                    . (
                    $parent
                    ? ( $parent->title =~ /Category (.*)/ )[0] . '.'
                    : ''
                    )
                    . $idx,
                position => $position,
            }
            );

        fill_categories( $count, $level - 1, $category );
    }
}
