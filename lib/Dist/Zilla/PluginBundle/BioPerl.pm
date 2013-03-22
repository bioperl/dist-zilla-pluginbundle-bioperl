package Dist::Zilla::PluginBundle::BioPerl;

# ABSTRACT: Build your distributions like Bioperl does

use Moose 1.00;
use MooseX::AttributeShortcuts;
use MooseX::Types::URI qw(Uri);
use MooseX::Types::Email qw(EmailAddress);
use MooseX::Types::Moose qw(ArrayRef Bool Str);
use namespace::autoclean;
with 'Dist::Zilla::Role::PluginBundle::Easy';

=head1 SYNOPSIS

  # dist.ini
  name = Dist-Zilla-Plugin-BioPerl
  ...
  
  [@BioPerl]

=head1 DESCRIPTION

This is the L<Dist::Zilla> configuration for the BioPerl project. It is roughly
equivalent to:

  [@Filter]
  -bundle = @Basic      ; the basic to maintain and release CPAN distros
  -remove = Readme      ; avoid conflict since we already have a README file
  
  [MetaConfig]          ; summarize Dist::Zilla configuration on distribution
  [MetaJSON]            ; produce a META.json
  [PkgVersion]          ; add a $version to the modules
  [PodSyntaxTests]      ; create a release test for Pod syntax
  [NoTabsTests]         ; create a release tests making sure hard tabs aren't used
  [NextRelease]         ; update release number on Changes file
  [Git::Check]          ; check working path for any uncommitted stuff
  [Git::Commit]         ; commit the dzil-generated stuff
  [Git::Tag]            ; tag our new release
  [Test::Compile]       ; test syntax of all modules
  [PodCoverageTests]    ; create release test for Pod coverage
  [AutoPrereqs]         ; automatically find the dependencies
  
  [AutoMetaResources]   ; automatically fill resources fields on metadata
  repository.github     = user:bioperl
  homepage              = http://search.cpan.org/dist/${dist}
  
  [MetaResources]       ; fill resources fields on metadata
  bugtracker.web        = https://redmine.open-bio.org/projects/bioperl/
  bugtracker.mailto     = bioperl-l@bioperl.org
  
  [Authority]           ; put the $AUTHORITY line in the modules and metadata
  authority             = cpan:CJFIELDS
  do_metadata           = 1
  
  [EOLTests]            ; create release tests for correct line endings
  trailing_whitespace   = 1
  
  [PodWeaver]
  config_plugin = @BioPerl

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

sub configure {
    my $self = shift;
    $self->add_bundle('@Filter' => {
        '-bundle' => '@Basic',
        '-remove' => ['Readme'],
    });

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
        [PodWeaver => {
            config_plugin => '@BioPerl',
        }],
    );

}

__PACKAGE__->meta->make_immutable;
1;
