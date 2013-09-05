package Schema::ResultSet::Category;
use utf8;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'DBIx::Class::ResultSet';

__PACKAGE__->load_components('Helper::ResultSet::Me');

sub descendants {
    my $self = shift;
    my $level = shift || 5;

    my $parent_id = $self->{cond}{ $self->me . 'parent_id' };

    $self->result_source->schema->resultset('Category::Descendants')
        ->search( undef, { bind => [ $parent_id, $level ] } );
}

__PACKAGE__->meta->make_immutable();

1;
