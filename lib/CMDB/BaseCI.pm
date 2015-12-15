package CMDB::BaseCI;

use Moose;
use MooseX::Storage;
use UUID::Tiny ':std';

has 'uuid' => (
    is => 'ro',
    required => 1,
    default => sub {
        create_uuid_as_string(UUID_V4);
    }
);

with Storage (format => 'JSON', io => 'PgDocStore');

1;
