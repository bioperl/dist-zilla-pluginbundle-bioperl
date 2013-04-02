package Pod::Weaver::PluginBundle::BioPerl;
use utf8;

# ABSTRACT: Configure your POD like Bioperl does
# AUTHOR:   Carnë Draug <carandraug+dev@gmail.com
# OWNER:    2013 Carnë Draug
# LICENSE:  Perl_5

use strict;
use warnings;
use namespace::autoclean;
use Pod::Weaver::Config::Assembler;

=head1 SYNOPSIS

This L<Pod::Weaver> plugin bundle is used by L<Dist::Zilla::Pluginbundle::BioPerl>
so if you're using it, you're already using this as well. Otherwise, either add
to your F<.dist.ini>

  [PodWeaver]
  config_plugin = @BioPerl

or to your F<weaver.ini>

  [@BioPerl]

=head1 DESCRIPTION

This is the L<Pod::Weaver> configuration for the BioPerl project. It is roughly
equivalent to:

  [@CorePrep]
  [Name]
  [Version]

  [Region / prelude]

  [Generic / SYNOPSIS]
  [Generic / DESCRIPTION]
  [Generic / OVERVIEW]

  [Collect / ATTRIBUTES]
  command = attr
  [Collect / METHODS]
  command = method
  [Collect / FUNCTIONS]
  command = func
  [Collect / INTERNAL METHODS]
  command = internal

  [Leftovers]

  [Region / postlude]

  [GenerateSection / FEEDBACK]
  head = 1
  [GenerateSection / Mailing lists]
  head = 2
  text =
  [GenerateSection / Support]
  head = 2
  text =a rather long text
  [GenerateSection / Reporting bugs]
  head = 2
  text = a rather long text
  [Legal::Complicated]
  [Contributors]

  [-Encoding]
  encoding = utf-8

  [-Transformer]
  transformer = List

  [-EnsureUniqueSections]

=cut

=for Pod::Coverage _exp mvp_bundle_config
=cut

sub _exp { Pod::Weaver::Config::Assembler->expand_package($_[0]) }

sub mvp_bundle_config {
  return (
    ['@Bioperl/CorePrep',  _exp('@CorePrep'), {} ],
    ['@BioPerl/Name',      _exp('Name'),      {} ],
    ['@BioPerl/Version',   _exp('Version'),   {} ],

    ['@BioPerl/prelude',   _exp('Region'),    { region_name => 'prelude'  } ],

    ['SYNOPSIS',           _exp('Generic'),   {} ],
    ['DESCRIPTION',        _exp('Generic'),   {} ],
    ['OVERVIEW',           _exp('Generic'),   {} ],

    ['ATTRIBUTES',         _exp('Collect'),   { command => 'attr'     } ],
    ['METHODS',            _exp('Collect'),   { command => 'method'   } ],
    ['FUNCTIONS',          _exp('Collect'),   { command => 'func'     } ],
    ['INTERNAL METHODS',   _exp('Collect'),   { command => 'internal' } ],

    ['@BioPerl/Leftovers', _exp('Leftovers'), {} ],

    ['@BioPerl/postlude',  _exp('Region'),    { region_name => 'postlude' } ],

    ['FEEDBACK',           _exp('GenerateSection'), { head => 1                            } ],
    ['Mailing lists',      _exp('GenerateSection'), { head => 2, text => fback_lists()     } ],
    ['Support',            _exp('GenerateSection'), { head => 2, text => fback_support()   } ],
    ['Reporting bugs',     _exp('GenerateSection'), { head => 2, text => fback_reporting() } ],
    ['@BioPerl/Legal',     _exp('Legal::Complicated'), {}                                    ],
    ['@BioPerl/Contributors', _exp('Contributors'), {}                                       ],

    ['Encoding',           _exp('-Encoding'),       { encoding => 'utf-8' }  ],

    ['@BioPerl/List',      _exp('-Transformer'),    { transformer => 'List'} ],

    ['EnsureUniqueSections', _exp('-EnsureUniqueSections'), {} ],
  )
};

=for Pod::Coverage fback_lists fback_support fback_reporting
=cut

sub fback_lists {
  return ["User feedback is an integral part of the evolution of this and other",
          "Bioperl modules. Send your comments and suggestions preferably to",
          "the Bioperl mailing list.  Your participation is much appreciated.",
          "",
          "  {{\$bugtracker_email}}                  - General discussion",
          "  http://bioperl.org/wiki/Mailing_lists  - About the mailing lists",
          ];
}

sub fback_support {
  return ["Please direct usage questions or support issues to the mailing list:",
          "I<{{\$bugtracker_email}}>",
          "",
          "rather than to the module maintainer directly. Many experienced and",
          "reponsive experts will be able look at the problem and quickly",
          "address it. Please include a thorough description of the problem",
          "with code and data examples if at all possible.",
          ];
}

sub fback_reporting {
  return ["Report bugs to the Bioperl bug tracking system to help us keep track",
          "of the bugs and their resolution. Bug reports can be submitted via the",
          "web:",
          "",
          "  {{\$bugtracker_web}}",
          ];
}

1;
