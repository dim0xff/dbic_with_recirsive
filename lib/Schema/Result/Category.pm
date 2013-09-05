package Schema::Result::Category;
use utf8;

=head1 NAME

Schema::Result::Category

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

__PACKAGE__->table("categories");

__PACKAGE__->add_columns(
    "id" => {
        data_type         => "bigint",
        is_auto_increment => 1,
        is_nullable       => 0,
        sequence          => "categories_id_seq",
    },
    "parent_id" => {
        data_type      => "bigint",
        is_foreign_key => 1,
        is_nullable    => 1,
    },
    "title" => {
        data_type   => "varchar",
        is_nullable => 0,
    },
    "position" => {
        data_type     => "integer",
        default_value => 0,
        is_nullable   => 0,
    },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
    categories => "Schema::Result::Category",
    { "foreign.parent_id" => "self.id", },
    { cascade_copy        => 0, cascade_delete => 0 },
);

__PACKAGE__->belongs_to(
    "parent" => "Schema::Result::Category",
    { id => "parent_id", },
    {
        is_deferrable => 0,
        join_type     => "LEFT",
        on_delete     => "NO ACTION",
        on_update     => "NO ACTION",
    },
);

sub ancestors {
    my $self = shift;

    $self->result_source->schema->resultset('Category::Ancestors')
        ->search( undef, { bind => [ $self->id ] } );
}

__PACKAGE__->meta->make_immutable;
1;
