package Dist::Zilla::PluginBundle::FLORA;
# ABSTRACT: Build your distributions like FLORA does

use Moose 1.00;
use Method::Signatures::Simple;
use MooseX::Types::URI qw(Uri);
use MooseX::Types::Moose qw(Bool Str CodeRef);
use MooseX::Types::Structured 0.20 qw(Map Dict Optional);
use namespace::autoclean -also => 'lower';

has dist => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has auto_prereq => (
    is      => 'ro',
    isa     => Bool,
    default => 1,
);

has is_task => (
    is      => 'ro',
    isa     => Bool,
    lazy    => 1,
    builder => '_build_is_task',
);

method _build_is_task {
    return $self->dist =~ /^Task-/ ? 1 : 0;
}

has bugtracker_url => (
    isa     => Uri,
    coerce  => 1,
    lazy    => 1,
    builder => '_build_bugtracker_url',
    handles => {
        bugtracker_url => 'as_string',
    },
);

method _build_bugtracker_url {
    return sprintf $self->_rt_uri_pattern, $self->dist;
}

has _rt_uri_pattern => (
    is      => 'ro',
    isa     => Str,
    default => 'http://rt.cpan.org/Public/Dist/Display.html?Name=%s',
);

has homepage_url => (
    isa     => Uri,
    coerce  => 1,
    lazy    => 1,
    builder => '_build_homepage_url',
    handles => {
        homepage_url => 'as_string',
    },
);

method _build_homepage_url {
    return sprintf $self->_cpansearch_pattern, $self->dist;
}

has _cpansearch_pattern => (
    is      => 'ro',
    isa     => Str,
    default => 'http://search.cpan.org/dist/%s',
);

has repository => (
    is        => 'ro',
    isa       => Uri,
    coerce    => 1,
    predicate => 'has_repository',
);

has repository_at => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_repository_at',
);

has _repository_host_map => (
    traits  => [qw(Hash)],
    isa     => Map[Str, Dict[pattern => Str, mangle => Optional[CodeRef]]],
    builder => '_build__repository_host_map',
    handles => {
        _repository_data_for => 'get',
    },
);

sub lower { lc shift }

method _build__repository_host_map {
    return {
        github => { pattern => 'git://github.com/rafl/%s.git', mangle => \&lower },
        gitmo  => { pattern => 'git://git.moose.perl.org/gitmo/%s.git' },
        (map { ($_ => { pattern => "git://git.shadowcat.co.uk/${_}/%s.git" }) }
             qw(catagits p5sagit dbsrgits)),
    };
}

has _repository_url => (
    isa     => Uri,
    coerce  => 1,
    lazy    => 1,
    builder => '_build__repository_url',
    handles => {
        _repository_url => 'as_string',
    },
);

method _build__repository_url {
    return $self->repository if $self->has_repository;
    return $self->_resolve_repository($self->repository_at) if $self->has_repository_at;
    confess "one of repository or repository_at is required";
}

method _resolve_repository ($repo) {
    my $dist = $self->dist;
    my $data = $self->_repository_data_for($repo);
    return sprintf $data->{pattern}, (exists $data->{mangle} ? $data->{mangle}->($dist) : $dist);
}

override BUILDARGS => method ($class:) {
    my $args = super;
    return { %{ $args->{payload} }, %{ $args } };
};

method configure {
    $self->add_bundle('@Filter' => {
        bundle => '@Classic',
        remove => [qw(
            PodVersion
            BumpVersion
        )],
    });

    $self->add_plugins(qw(
        MetaConfig
        MetaJSON
    ));

    $self->add_plugins([ 'MetaResources' => {
        repository => $self->_repository_url,
        bugtracker => $self->bugtracker_url,
        homepage   => $self->homepage_url,
    }]);

    $self->is_task
        ? $self->add_plugins('TaskWeaver')
        : $self->add_plugins([ 'PodWeaver' => { config_plugin => '@FLORA' } ]);

    $self->add_plugins('AutoPrereq') if $self->auto_prereq;
}

with 'Dist::Zilla::Role::PluginBundle::Easy';

__PACKAGE__->meta->make_immutable;

1;
