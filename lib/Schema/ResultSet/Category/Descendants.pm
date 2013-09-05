package Schema::ResultSet::Category::Descendants;
use utf8;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'Schema::ResultSet::Category';

around all => sub {
    my $orig = shift;
    my $self = shift;

    my @all = $self->$orig;
    my @return;

    $self->_build_recursive_categories( \@all, \@return );

    return @return;
};

# Recursive building categories
sub _build_recursive_categories {
    my ( $self, $all, $return, $top ) = @_;

    my $prev;
    while ( my $category = shift( @{$all} ) ) {
        if ( !$top || !$category->parent_id ) {
            push( @{$return}, $category );

            $category->related_resultset('categories')->set_cache( [] )
                unless $category->related_resultset('categories')->get_cache;

            $self->_build_recursive_categories( $all, $return, $category );
        }
        elsif ( $top->id == $category->parent_id ) {
            push(
                @{ $top->related_resultset('categories')->get_cache },
                $category
            );
            $prev = $category;
        }
        elsif ( $prev && $prev->id == $category->parent_id ) {
            unshift( @{$all}, $category );

            $prev->related_resultset('categories')->set_cache( [] )
                unless $prev->related_resultset('categories')->get_cache;

            $self->_build_recursive_categories( $all, $return, $prev );
        }
        else {
            unshift( @{$all}, $category );
            return;
        }
    }
}

__PACKAGE__->meta->make_immutable();

1;
