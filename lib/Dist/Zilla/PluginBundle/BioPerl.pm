package Dist::Zilla::PluginBundle::BioPerl;

# ABSTRACT: Build your distributions like Bioperl does

use Moose 1.00;
use MooseX::AttributeShortcuts;
use MooseX::Types::URI qw(Uri);
use MooseX::Types::Email qw(EmailAddress);
use MooseX::Types::Moose qw(Bool Str CodeRef);
#use Moose::Util::TypeConstraints;
#use MooseX::Types::Structured 0.20 qw(Map Dict Optional);
use namespace::autoclean;
with 'Dist::Zilla::Role::PluginBundle::Easy';

=head1 SYNOPSIS

  # dist.ini
  name = Dist-Zilla-Plugin-AutoMetaResources
  ...
  
  [@BioPerl]

=head1 DESCRIPTION

This is the L<Dist::Zilla> configuration for the BioPerl project. It is roughly
equivalent to:

  [@Basic]

  [MetaConfig]
  [MetaJSON]
  [PkgVersion]
  [PodSyntaxTests]
  [NoTabsTests]
  [NextRelease]
  [Git::Check]
  [Git::Commit]
  [Git::Tag]
  [Test::Compile]
  [PodCoverageTests]
  [AutoPrereqs]
  
  [AutoMetaResources]
  repository.github = user:bioperl
  homepage          = http://search.cpan.org/dist/${dist}
  
  [MetaResources]
  bugtracker.web    = https://redmine.open-bio.org/projects/bioperl/
  bugtracker.mailto = bioperl-l@bioperl.org
  
  [Authority]
  authority         = cpan:CJFIELDS
  do_metadata       = 1
  
  [EOLTests]
  trailing_whitespace = 1
  
  # NOT ENABLED YET!
  #[PodWeaver]
  #config_plugin = @FLORA

=head1 CONFIGURATION

Use the L<Dist::Zilla::PluginBundle::Filter> to filter any undesired plugin
that is part of the default set. This also allows to change those plugins
default values. However, the BioPerl bundle already recognizes some of the
plugins options and will pass it to the corresponding plugin. If any is missing,
please consider patching this bundle.

In some cases, this bundle will also perform some sanity checks before passing
the value to the original plugin.

=over

=item homepage

Same option used by the L<Dist::Zilla::Plugin::AutoMetaResources>

=item repository.github

Same option used by the L<Dist::Zilla::Plugin::AutoMetaResources>

=item bugtracker.web

Same option used by the L<Dist::Zilla::Plugin::MetaResources>

=item bugtracker.mailto

Same option used by the L<Dist::Zilla::Plugin::MetaResources>

=item authority

Same option used by the L<Dist::Zilla::Plugin::Authority>

=item trailing_whitespace

Same option used by the L<Dist::Zilla::Plugin::EOLTests>

=back

=cut

sub get_value {
    my ($self, $accessor) = @_;
    my %defaults = (
        'homepage'            => 'http://search.cpan.org/dist/%{dist}',
        'repository.github'   => 'user:bioperl',
        'bugtracker.web'      => 'https://redmine.open-bio.org/projects/bioperl/',
        'bugtracker.mailto'   => 'bioperl-l@bioperl.org',
        'authority'           => 'cpan:CJFIELDS',
        'trailing_whitespace' => 1,
    );
    return $self->payload->{$accessor} || $defaults{$accessor};
}

has homepage => (
    is      => 'lazy',
    isa     => Str,
    default => sub { shift->get_value('homepage') }
);

has repository_github => (
    is      => 'lazy',
    isa     => Str,
    default => sub { shift->get_value('repository.github') }
);

has bugtracker_web => (
    is      => 'lazy',
    isa     => Uri,
    coerce  => 1,
    default => sub { shift->get_value('bugtracker.web') }
);

has bugtracker_mailto => (
    is      => 'lazy',
    isa     => EmailAddress,
    default => sub { shift->get_value('bugtracker.mailto') }
);

has authority => (
    is      => 'lazy',
    isa     => Str,
    default => sub { shift->get_value('authority') }
);

has trailing_whitespace => (
    is      => 'lazy',
    isa     => Bool,
    default => sub { shift->get_value('trailing_whitespace') }
);

##
## these commented blocks of text may be used one day to deal with podweaver
##

#has is_task => (
#    is      => 'ro',
#    isa     => Bool,
#    lazy    => 1,
#    builder => '_build_is_task',
#);
#
#sub _build_is_task {
#    my $self = shift;
#    return $self->dist =~ /^Task-/ ? 1 : 0;
#}
#
#has weaver_config_plugin => (
#    is      => 'ro',
#    isa     => Str,
#    default => '@FLORA',  # TODO: needs to change
#);
#
#my $map_tc = Map[
#    Str, Dict[
#        pattern     => CodeRef,
#        web_pattern => CodeRef,
#        type        => Optional[Str],
#        mangle      => Optional[CodeRef],
#    ]
#];
#
#coerce $map_tc, from Map[
#    Str, Dict[
#        pattern     => Str|CodeRef,
#        web_pattern => Str|CodeRef,
#        type        => Optional[Str],
#        mangle      => Optional[CodeRef],
#    ]
#], via {
#    my %in = %{ $_ };
#    return { map {
#        my $k = $_;
#        ($k => {
#            %{ $in{$k} },
#            (map {
#                my $v = $_;
#                (ref $in{$k}->{$v} ne 'CODE'
#                     ? ($v => sub { $in{$k}->{$v} })
#                     : ()),
#            } qw(pattern web_pattern)),
#        })
#    } keys %in };
#};

sub configure {
    my $self = shift;
    $self->add_bundle('@Basic');

    $self->add_plugins(qw(
        MetaConfig
        MetaJSON
        PkgVersion
        PodSyntaxTests
        NoTabsTests
        NextRelease
        Git::Check
        Git::Commit
        Git::Tag
        Test::Compile
        PodCoverageTests
        AutoPrereqs
    ));

    $self->add_plugins(
        [AutoMetaResources => [
            'repository.github' => $self->repository_github,
            'homepage'          => $self->homepage,
        ]],
        ## AutoMetaResources does not let us configure the bugtracker
        [MetaResources => [
            'bugtracker.web'    => $self->bugtracker_web,
            'bugtracker.mailto' => $self->bugtracker_mailto,
        ]],
        [Authority => {
            authority   => $self->authority,
            do_metadata => 1,
        }],
        [EOLTests => {
            trailing_whitespace => $self->trailing_whitespace,
        }],
    );

    # TODO: figure out and migrate to a Bioperl-wide PodWeaver config
    # plugin.  this will require deleting large amounts of POD
    # boilerplate from the existing codebase. -- rbuels
    # $self->is_task
    #     ? $self->add_plugins('TaskWeaver')
    #     : $self->add_plugins(
    #           [PodWeaver => {
    #               config_plugin => $self->weaver_config_plugin,
    #           }],
    #       );
}

__PACKAGE__->meta->make_immutable;
1;
