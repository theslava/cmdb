package CMDB::Schema;

use Moose;
use namespace::autoclean;

use Carp;
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
    for my $file (@{ $self->files }) {
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

sub CMDB::Schema::INC {
    my ($self, $class) = @_;
    $class =~ s/\.pm$//;
    $class =~ s/\/+/::/g;
    $class = $self->schema->{classes}->{lc $class};
    return unless $class;

    Moose::Meta::Class->create(
        $class->{name} => (
            'superclasses' => [ 'CMDB::BaseCI', ],
            'attributes' => [
                map { Moose::Meta::Attribute->new( $_, is => 'rw', documentation => $class->{properties}->{$_}->{name} )} keys %{ $class->{properties} }
            ],
        )
    )->make_immutable;
    my $scalar = q{1;};
    return (\$scalar);
}

__PACKAGE__->meta->make_immutable;

1;
