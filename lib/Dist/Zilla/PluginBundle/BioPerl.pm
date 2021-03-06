package Dist::Zilla::PluginBundle::BioPerl;

use utf8;

# ABSTRACT: Build your distributions like Bioperl does
# AUTHOR:   Florian Ragwitz <rafl@debian.org>
# AUTHOR:   Sheena Scroggins
# AUTHOR:   Carnë Draug <carandraug+dev@gmail.com>
# AUTHOR:   Chris Fields <cjfields1@gmail.com>
# OWNER:    2010 Florian Ragwitz
# OWNER:    2011 Sheena Scroggins
# OWNER:    2013-2017 Carnë Draug
# LICENSE:  Perl_5

use Moose 1.00;
use MooseX::AttributeShortcuts;
use MooseX::Types::Email qw(EmailAddress);
use MooseX::Types::Moose qw(ArrayRef Bool Str);
use namespace::autoclean;

with qw(
  Dist::Zilla::Role::PluginBundle::Easy
  Dist::Zilla::Role::PluginBundle::PluginRemover
  Dist::Zilla::Role::PluginBundle::Config::Slicer
);

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
  [Test::NoTabs]        ; create a release tests making sure hard tabs aren't used
  [Test::Compile]       ; test syntax of all modules
  [PodCoverageTests]    ; create release test for Pod coverage
  [MojibakeTests]       ; create release test for correct encoding
  [AutoPrereqs]         ; automatically find the dependencies

  [AutoMetaResources]   ; automatically fill resources fields on metadata
  repository.github     = user:bioperl
  bugtracker.github     = user:bioperl
  homepage              = https://metacpan.org/release/${dist}

  [MetaResources]       ; fill resources fields on metadata
  bugtracker.mailto     = bioperl-l@bioperl.org

  [Test::EOL]           ; create release tests for correct line endings
  trailing_whitespace = 1

  ;; While data files for the test units are often text files, they
  ;; need to be treated as bytes.  This has the side effect of having
  ;; them ignored by [Test::NoTabs] and [Test::EOL]
  [Encoding]
  encoding = bytes
  match = ^t/data/

  [PodWeaver]
  config_plugin = @BioPerl

  [NextRelease]         ; update release number on Changes file
  [Git::Check]          ; check working path for any uncommitted stuff
  allow_dirty = Changes
  allow_dirty = dist.ini
  [Git::Commit]         ; commit the dzil-generated stuff
  allow_dirty = Changes
  allow_dirty = dist.ini
  [Git::Tag]            ; tag our new release
  tag_format  = %N-v%v
  tag_message = %N-v%v

In addition, this also has two roles, L<Dist::Zilla::PluginBundle::PluginRemover> and
Dist::Zilla::PluginBundle::Config::Slice, so one could do something like this for
problematic distributions:

  [@BioPerl]
  -remove = MojibakeTests
  -remove = PodSyntaxTests

=head1 Pushing releases

With this PluginBundle, there's a lot of things happening
automatically. It might not be clear what actually needs to be done
and what will be done automatically unless you are already familiar
with all the plugins being used.  Assuming that F<Changes> is up
to date (you should be updating F<Changes> as the changes are made
and not when preparing a release.  If you need to add notes to that
file, then do it do it at the same time you bump the version number in
F<dist.ini>), the following steps will make a release:

=for :list
1. Make sure the working directory is clean with `git status'.
2. Run `dzil test --all'
3. Edit dist.ini to bump the version number only.
4. Run `dzil release'
5. Run `git push --follow-tags'

These steps will automatically do the following:

=for :list
* Modify F<Changes> with the version number and time of release.
* Make a git commit with the changes to F<Changes> and F<dist.ini>
  using a standard commit message.
* Add a lightweight git tag for the release.
* Run the tests (including a series of new tests for maintainers only)
  and push release to CPAN.

=head1 CONFIGURATION

Use the L<Dist::Zilla::PluginBundle::Filter> to filter any undesired plugin
that is part of the default set. This also allows to change those plugins
default values. However, the BioPerl bundle already recognizes some of the
plugins options and will pass it to the corresponding plugin. If any is missing,
please consider patching this bundle.

In some cases, this bundle will also perform some sanity checks before passing
the value to the original plugin.

=for :list
* homepage
Same option used by the L<Dist::Zilla::Plugin::AutoMetaResources>
* repository.github
Same option used by the L<Dist::Zilla::Plugin::AutoMetaResources>
* bugtracker.github
Same option used by the L<Dist::Zilla::Plugin::AutoMetaResources>
* bugtracker.mailto
Same option used by the L<Dist::Zilla::Plugin::MetaResources>
* trailing_whitespace
Same option used by the L<Dist::Zilla::Plugin::EOLTests>
* allow_dirty
Same option used by the L<Dist::Zilla::Plugin::Git::Commit> and
L<Dist::Zilla::Plugin::Git::Check>

=cut

=for Pod::Coverage get_value
=cut

sub get_value {
    my ($self, $accessor) = @_;
    my %defaults = (
        'homepage'            => 'https://metacpan.org/release/%{dist}',
        'repository.github'   => 'user:bioperl',
        'bugtracker.github'   => 'user:bioperl',
        'bugtracker.mailto'   => 'bioperl-l@bioperl.org',
        'trailing_whitespace' => 1,
        'allow_dirty'         => ['Changes', 'dist.ini'],
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

has bugtracker_github => (
    is      => 'lazy',
    isa     => Str,
    default => sub { shift->get_value('bugtracker.github') }
);

has bugtracker_mailto => (
    is      => 'lazy',
    isa     => EmailAddress,
    default => sub { shift->get_value('bugtracker.mailto') }
);

has trailing_whitespace => (
    is      => 'lazy',
    isa     => Bool,
    default => sub { shift->get_value('trailing_whitespace') }
);

=for Pod::Coverage mvp_multivalue_args
=cut

sub mvp_multivalue_args { qw( allow_dirty ) }
has allow_dirty => (
    is      => 'lazy',
    isa     => ArrayRef,
    default => sub { shift->get_value('allow_dirty') }
);

=for Pod::Coverage configure
=cut

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
        Test::NoTabs
        Test::Compile
        PodCoverageTests
        MojibakeTests
        AutoPrereqs
    ));

    my @allow_dirty;
    foreach (@{$self->allow_dirty}) {
        push (@allow_dirty, 'allow_dirty', $_);
    }

    $self->add_plugins(
        [AutoMetaResources => [
            'repository.github' => $self->repository_github,
            'homepage'          => $self->homepage,
            'bugtracker.github' => $self->bugtracker_github,
        ]],
        [MetaResources => [
            'bugtracker.mailto' => $self->bugtracker_mailto,
        ]],
        ['Test::EOL' => {
            trailing_whitespace => $self->trailing_whitespace,
        }],
        [Encoding => [
             'encoding' => 'bytes',
             'match' => '^t/data/',
        ]],
        [PodWeaver => {
            config_plugin => '@BioPerl',
        }],
    );

    $self->add_plugins(qw(
        NextRelease
    ));

    $self->add_plugins(
        ['Git::Check' => [
            @allow_dirty,
        ]],
        ['Git::Commit' => [
            @allow_dirty,
        ]],
        ['Git::Tag' => [
            tag_format  => '%N-v%v',
            tag_message => '%N-v%v',
        ]],
    );
}

__PACKAGE__->meta->make_immutable;
1;
