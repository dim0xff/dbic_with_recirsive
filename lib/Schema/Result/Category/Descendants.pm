package Schema::Result::Category::Descendants;
use utf8;

=head1 NAME

Schema::Result::Category::Descendants;

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'Schema::Result::Category';

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

__PACKAGE__->table("categories");

__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition(
    q[ SELECT c.* FROM get_category_descendants(?, ?) as c ] );

__PACKAGE__->meta->make_immutable;
1;
