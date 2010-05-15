package Dist::Zilla::PluginBundle::FLORA;
# ABSTRACT: Build your distributions like FLORA does

use Moose 1.00;
use Method::Signatures::Simple;
use Moose::Util::TypeConstraints;
use MooseX::Types::URI qw(Uri);
use MooseX::Types::Moose qw(Bool Str CodeRef);
use MooseX::Types::Structured 0.20 qw(Map Dict Optional);
use namespace::autoclean -also => 'lower';

=head1 SYNOPSIS

In dist.ini:

  [@FLORA]
  dist = Distribution-Name
  repository_at = github

=head1 DESCRIPTION

This is the L<Dist::Zilla> configuration I use to build my
distributions.

It is roughly equivalent to:

  [@Filter]
  bundle = @Classic
  remove = PodVersion
  remove = BumpVersion

  [MetaConfig]
  [MetaJSON]

  [MetaResources]
  repository = git://github.com/rafl/${lowercase_distribution}
  bugtracker = http://rt.cpan.org/Public/Dist/Display.html?Name=${dist}
  homepage   = http://search.cpan.org/dist/${dist}

  [PodWeaver]
  config_plugin = @FLORA

  [AutoPrereq]

=cut

has dist => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has authority => (
    is      => 'ro',
    isa     => Str,
    default => 'cpan:FLORA',
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

has github_user => (
    is      => 'ro',
    isa     => Str,
    default => 'rafl',
);

my $map_tc = Map[Str, Dict[pattern => CodeRef, mangle => Optional[CodeRef]]];
coerce $map_tc, from Map[Str, Dict[pattern => Str|CodeRef, mangle => Optional[CodeRef]]], via {
    my %in = %{ $_ };
    for my $k (keys %in) {
        $in{$k}->{pattern} = sub { $in{$k}->{pattern} }
            unless ref $in{$k}->{pattern} eq 'CODE';
    }
    return \%in;
};

has _repository_host_map => (
    traits  => [qw(Hash)],
    isa     => $map_tc,
    coerce  => 1,
    lazy    => 1,
    builder => '_build__repository_host_map',
    handles => {
        _repository_data_for => 'get',
    },
);

sub lower { lc shift }

method _build__repository_host_map {
    my $github_pattern = sub { sprintf 'git://github.com/%s/%%s.git', $self->github_user };

    return {
        github => { pattern => $github_pattern, mangle => \&lower },
        GitHub => { pattern => $github_pattern },
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
    confess "unknown repository service $repo" unless $data;
    return sprintf $data->{pattern}->(), (exists $data->{mangle} ? $data->{mangle}->($dist) : $dist);
}

override BUILDARGS => method ($class:) {
    my $args = super;
    return { %{ $args->{payload} }, %{ $args } };
};

method configure {
    $self->add_bundle('@Basic');

    $self->add_plugins(qw(
        MetaConfig
        MetaJSON
        PkgVersion
        PodSyntaxTests
        PodCoverageTests
    ));

    $self->add_plugins(
        [MetaResources => {
            repository => $self->_repository_url,
            bugtracker => $self->bugtracker_url,
            homepage   => $self->homepage_url,
        }],
        [Authority => {
            authority   => $self->authority,
            do_metadata => 1,
        }]
    );


    $self->is_task
        ? $self->add_plugins('TaskWeaver')
        : $self->add_plugins([ 'PodWeaver' => { config_plugin => '@FLORA' } ]);

    $self->add_plugins('AutoPrereq') if $self->auto_prereq;
}

with 'Dist::Zilla::Role::PluginBundle::Easy';

__PACKAGE__->meta->make_immutable;

1;
