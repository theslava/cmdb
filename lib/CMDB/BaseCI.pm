package CMDB::BaseCI;

use Moose;
use namespace::autoclean;

use MooseX::Storage;
use MooseX::Types::UUID qw(UUID);
use UUID::Tiny ':std';

has 'uuid' => (
    is => 'ro',
    isa => UUID,
    required => 1,
    default => sub {
        create_uuid_as_string(UUID_V4);
    }
);

with Storage ( format => 'JSON', io => 'PgJSON' );

__PACKAGE__->meta->make_immutable;

1;
