package CMDB::Schema;

use Moose;
use namespace::autoclean;

use JSON;
use Hash::Merge qw( merge );

has 'files' => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    required => 1,
);

has 'schema' => (
    is => 'ro',
    isa => 'HashRef',
    lazy => 1,
    builder => '_schema',
);

sub _schema {
    my $self = shift;
    my $schema = {};
    for my $file ($self->files) {
        my $cim = eval {
            local $/ = undef;
            open my $fh, q{<}, $file;
            my $ret = <$fh>;
            close $fh;
            return decode_json($ret);
        };
        $schema = merge $schema, $cim;
    }
    return $schema;
}

__PACKAGE__->meta->make_immutable;

1;
