package Pod::MyLaTeX;

=head1 NAME

Pod::LaTeX - Convert Pod data to formatted Latex

=head1 SYNOPSIS

  use Pod::LaTeX;
  my $parser = Pod::LaTeX->new ( );

  $parser->parse_from_filehandle;

  $parser->parse_from_file ('file.pod', 'file.tex');

=head1 DESCRIPTION

C<Pod::LaTeX> is a module to convert documentation in the Pod format
into Latex. The L<B<pod2latex>|pod2latex> X<pod2latex> command uses
this module for translation.

C<Pod::LaTeX> is a derived class from L<Pod::Select|Pod::Select>.

=cut


use strict;
use Data::Dumper;
require Pod::ParseUtils;
use base qw/ Pod::Select /;
use Carp;

use vars qw/ $VERSION %HTML_Escapes @LatexSections /;

$VERSION = '0.54';

# Definitions of =headN -> latex mapping
@LatexSections = (qw/
		  chapter
		  section
		  subsection
		  subsubsection
		  paragraph
		  subparagraph
		  /);

# Standard escape sequences converted to Latex
# Up to "yuml" these are taken from the original pod2latex
# command written by Taro Kawagish (kawagish@imslab.co.jp)


%HTML_Escapes = (
    # lt, gt and verbar are inserted without math mode
    # since the $$ will be added during general correction
    # for those escape characters
    'amp'       =>      '\&',      #   ampersand
    'lt'        =>      '<',    #   ' left chevron, less-than
    'gt'        =>      '>',    #   ' right chevron, greater-than
    'quot'      =>      '"',      #   double quote
    'sol'       =>      '/',
    'verbar'    =>      '|',

    "Aacute"    =>      "\\'{A}",       #   capital A, acute accent
    "aacute"    =>      "\\'{a}",       #   small a, acute accent
    "Acirc"     =>      "\\^{A}",       #   capital A, circumflex accent
    "acirc"     =>      "\\^{a}",       #   small a, circumflex accent
    "AElig"     =>      '\\AE',         #   capital AE diphthong (ligature)
    "aelig"     =>      '\\ae',         #   small ae diphthong (ligature)
    "Agrave"    =>      "\\`{A}",       #   capital A, grave accent
    "agrave"    =>      "\\`{a}",       #   small a, grave accent
    "Aring"     =>      '\\u{A}',       #   capital A, ring
    "aring"     =>      '\\u{a}',       #   small a, ring
    "Atilde"    =>      '\\~{A}',       #   capital A, tilde
    "atilde"    =>      '\\~{a}',       #   small a, tilde
    "Auml"      =>      '\\"{A}',       #   capital A, dieresis or umlaut mark
    "auml"      =>      '\\"{a}',       #   small a, dieresis or umlaut mark
    "Ccedil"    =>      '\\c{C}',       #   capital C, cedilla
    "ccedil"    =>      '\\c{c}',       #   small c, cedilla
    "Eacute"    =>      "\\'{E}",       #   capital E, acute accent
    "eacute"    =>      "\\'{e}",       #   small e, acute accent
    "Ecirc"     =>      "\\^{E}",       #   capital E, circumflex accent
    "ecirc"     =>      "\\^{e}",       #   small e, circumflex accent
    "Egrave"    =>      "\\`{E}",       #   capital E, grave accent
    "egrave"    =>      "\\`{e}",       #   small e, grave accent
    "ETH"       =>      '\\OE',         #   capital Eth, Icelandic
    "eth"       =>      '\\oe',         #   small eth, Icelandic
    "Euml"      =>      '\\"{E}',       #   capital E, dieresis or umlaut mark
    "euml"      =>      '\\"{e}',       #   small e, dieresis or umlaut mark
    "Iacute"    =>      "\\'{I}",       #   capital I, acute accent
    "iacute"    =>      "\\'{i}",       #   small i, acute accent
    "Icirc"     =>      "\\^{I}",       #   capital I, circumflex accent
    "icirc"     =>      "\\^{i}",       #   small i, circumflex accent
    "Igrave"    =>      "\\`{I}",       #   capital I, grave accent
    "igrave"    =>      "\\`{i}",       #   small i, grave accent
    "Iuml"      =>      '\\"{I}',       #   capital I, dieresis or umlaut mark
    "iuml"      =>      '\\"{i}',       #   small i, dieresis or umlaut mark
    "Ntilde"    =>      '\\~{N}',       #   capital N, tilde
    "ntilde"    =>      '\\~{n}',       #   small n, tilde
    "Oacute"    =>      "\\'{O}",       #   capital O, acute accent
    "oacute"    =>      "\\'{o}",       #   small o, acute accent
    "Ocirc"     =>      "\\^{O}",       #   capital O, circumflex accent
    "ocirc"     =>      "\\^{o}",       #   small o, circumflex accent
    "Ograve"    =>      "\\`{O}",       #   capital O, grave accent
    "ograve"    =>      "\\`{o}",       #   small o, grave accent
    "Oslash"    =>      "\\O",          #   capital O, slash
    "oslash"    =>      "\\o",          #   small o, slash
    "Otilde"    =>      "\\~{O}",       #   capital O, tilde
    "otilde"    =>      "\\~{o}",       #   small o, tilde
    "Ouml"      =>      '\\"{O}',       #   capital O, dieresis or umlaut mark
    "ouml"      =>      '\\"{o}',       #   small o, dieresis or umlaut mark
    "szlig"     =>      '\\ss{}',       #   small sharp s, German (sz ligature)
    "THORN"     =>      '\\L',          #   capital THORN, Icelandic
    "thorn"     =>      '\\l',,         #   small thorn, Icelandic
    "Uacute"    =>      "\\'{U}",       #   capital U, acute accent
    "uacute"    =>      "\\'{u}",       #   small u, acute accent
    "Ucirc"     =>      "\\^{U}",       #   capital U, circumflex accent
    "ucirc"     =>      "\\^{u}",       #   small u, circumflex accent
    "Ugrave"    =>      "\\`{U}",       #   capital U, grave accent
    "ugrave"    =>      "\\`{u}",       #   small u, grave accent
    "Uuml"      =>      '\\"{U}',       #   capital U, dieresis or umlaut mark
    "uuml"      =>      '\\"{u}',       #   small u, dieresis or umlaut mark
    "Yacute"    =>      "\\'{Y}",       #   capital Y, acute accent
    "yacute"    =>      "\\'{y}",       #   small y, acute accent
    "yuml"      =>      '\\"{y}',       #   small y, dieresis or umlaut mark

    # Added by TimJ

    "iexcl"  =>   '!`',           # inverted exclamation mark
#    "cent"   =>   ' ',        # cent sign
    "pound"  =>   '\pounds',      # (UK) pound sign
#    "curren" =>   ' ',        # currency sign
#    "yen"    =>   ' ',        # yen sign
#    "brvbar" =>   ' ',        # broken vertical bar
    "sect"   =>   '\S',           # section sign
    "uml"    =>   '\"{}',        # diaresis
    "copy"   =>   '\copyright',   # Copyright symbol
#    "ordf"   =>   ' ',        # feminine ordinal indicator
    "laquo"  =>   '$\ll$',      # ' # left pointing double angle quotation mark
    "not"    =>   '$\neg$',       # '  # not sign
    "shy"    =>   '-',            # soft hyphen
#    "reg"    =>   ' ',        # registered trademark
    "macr"   =>   '$^-$',         # ' # macron, overline
    "deg"    =>   '$^\circ$',     # '  # degree sign
    "plusmn" =>   '$\pm$',        # ' # plus-minus sign
    "sup2"   =>   '$^2$',         # ' # superscript 2
    "sup3"   =>   '$^3$',         # ' # superscript 3
    "acute"  =>   "\\'{}",        # acute accent
    "micro"  =>   '$\mu$',        # micro sign
    "para"   =>   '\P',           # pilcrow sign = paragraph sign
    "middot" =>   '$\cdot$',      # middle dot = Georgian comma
    "cedil"  =>   '\c{}',        # cedilla
    "sup1"   =>   '$^1$',         # ' # superscript 1
#    "ordm"   =>   ' ',        # masculine ordinal indicator
    "raquo"  =>   '$\gg$',     # ' # right pointing double angle quotation mark
    "frac14" =>   '$\frac{1}{4}$',   # ' # vulgar fraction one quarter
    "frac12" =>   '$\frac{1}{2}$',   # ' # vulgar fraction one half
    "frac34" =>   '$\frac{3}{4}$',   # ' # vulgar fraction three quarters
    "iquest" =>   "?'",              # inverted question mark
    "times"  =>   '$\times$',        # ' # multiplication sign
    "divide" =>   '$\div$',          # division sign

    # Greek letters using HTML codes
    "alpha"  =>   '$\alpha$',   # '
    "beta"   =>   '$\beta$',    # '
    "gamma"  =>   '$\gamma$',   # '
    "delta"  =>   '$\delta$',   # '
    "epsilon"=>   '$\epsilon$', # '
    "zeta"   =>   '$\zeta$',    # '
    "eta"    =>   '$\eta$',     # '
    "theta"  =>   '$\theta$',   # '
    "iota"   =>   '$\iota$',    # '
    "kappa"  =>   '$\kappa$',   # '
    "lambda" =>   '$\lambda$',  # '
    "mu"     =>   '$\mu$',      # '
    "nu"     =>   '$\nu$',      # '
    "xi"     =>   '$\xi$',      # '
    "omicron"=>   '$o$',        # '
    "pi"     =>   '$\pi$',      # '
    "rho"    =>   '$\rho$',     # '
    "sigma"  =>   '$\sigma$',   # '
    "tau"    =>   '$\tau$',     # '
    "upsilon"=>   '$\upsilon$', # '
    "phi"    =>   '$\phi$',     # '
    "chi"    =>   '$\chi$',     # '
    "psi"    =>   '$\psi$',     # '
    "omega"  =>   '$\omega$',   # '

    "Alpha"  =>   '$A$',   # '
    "Beta"   =>   '$B$',    # '
    "Gamma"  =>   '$\Gamma$',   # '
    "Delta"  =>   '$\Delta$',   # '
    "Epsilon"=>   '$E$', # '
    "Zeta"   =>   '$Z$',    # '
    "Eta"    =>   '$H$',     # '
    "Theta"  =>   '$\Theta$',   # '
    "Iota"   =>   '$I$',    # '
    "Kappa"  =>   '$K$',   # '
    "Lambda" =>   '$\Lambda$',  # '
    "Mu"     =>   '$M$',      # '
    "Nu"     =>   '$N$',      # '
    "Xi"     =>   '$\Xi$',      # '
    "Omicron"=>   '$O$',        # '
    "Pi"     =>   '$\Pi$',      # '
    "Rho"    =>   '$R$',     # '
    "Sigma"  =>   '$\Sigma$',   # '
    "Tau"    =>   '$T$',     # '
    "Upsilon"=>   '$\Upsilon$', # '
    "Phi"    =>   '$\Phi$',     # '
    "Chi"    =>   '$X$',     # '
    "Psi"    =>   '$\Psi$',     # '
    "Omega"  =>   '$\Omega$',   # '


);


=head1 OBJECT METHODS

The following methods are provided in this module. Methods inherited
from C<Pod::Select> are not described in the public interface.

=over 4

=begin __PRIVATE__

=item C<initialize>

Initialise the object. This method is subclassed from C<Pod::Parser>.
The base class method is invoked. This method defines the default
behaviour of the object unless overridden by supplying arguments to
the constructor. 

Internal settings are defaulted as well as the public instance data.
Internal hash values are accessed directly (rather than through
a method) and start with an underscore.

This method should not be invoked by the user directly.

=end __PRIVATE__

=cut



#   - An array for nested lists

# Arguments have already been read by this point

sub initialize {
  my $self = shift;

  # print Dumper($self);

  # Internals
  $self->{_Lists} = [];             # For nested lists
  $self->{_suppress_all_para}  = 0; # For =begin blocks
  $self->{_dont_modify_any_para}=0; # For =begin blocks
  $self->{_CURRENT_HEAD1}   = '';   # Name of current HEAD1 section

  # Options - only initialise if not already set

  # Cause the '=head1 NAME' field to be treated specially
  # The contents of the NAME paragraph will be converted
  # to a section title. All subsequent =head1 will be converted
  # to =head2 and down. Will not affect =head1's prior to NAME 
  # Assumes:  'Module - purpose' format
  # Also creates a purpose field
  # The name is used for Labeling of the subsequent subsections
  $self->{ReplaceNAMEwithSection} = 0
    unless exists $self->{ReplaceNAMEwithSection};
  $self->{AddPreamble}      = 1    # make full latex document
    unless exists $self->{AddPreamble};
  $self->{StartWithNewPage} = 0    # Start new page for pod section
    unless exists $self->{StartWithNewPage};
  $self->{TableOfContents}  = 0    # Add table of contents
    unless exists $self->{TableOfContents};  # only relevent if AddPreamble=1
   $self->{AddPostamble}     = 1          # Add closing latex code at end
    unless exists $self->{AddPostamble}; #  effectively end{document} and index
  $self->{MakeIndex}        = 1         # Add index (only relevant AddPostamble
    unless exists $self->{MakeIndex};   # and AddPreamble)

  $self->{UniqueLabels}     = 1          # Use label unique for each pod
    unless exists $self->{UniqueLabels}; # either based on the filename
                                         # or supplied

  # Control the level of =head1. default is \section
  # 
  $self->{Head1Level}     = 1   # Offset in latex sections
    unless exists $self->{Head1Level}; # 0 is chapter, 2 is subsection

  # Control at which level numbering of sections is turned off
  # ie subsection becomes subsection*
  # The numbering is relative to the latex sectioning commands
  # and is independent of Pod heading level
  # default is to number \section but not \subsection
  $self->{LevelNoNum} = 2
    unless exists $self->{LevelNoNum};

  # Label to be used as prefix to all internal section names
  # If not defined will attempt to derive it from the filename
  # This can not happen when running parse_from_filehandle though
  # hence the ability to set the label externally
  # The label could then be Pod::Parser_DESCRIPTION or somesuch

  $self->{Label}            = undef # label to be used as prefix
    unless exists $self->{Label};   # to all internal section names

  # These allow the caller to add arbritrary latex code to
  # start and end of document. AddPreamble and AddPostamble are ignored
  # if these are set.
  # Also MakeIndex and TableOfContents are also ignored.
  $self->{UserPreamble}     = undef # User supplied start (AddPreamble =1)
    unless exists $self->{Label};
  $self->{UserPostamble}    = undef # Use supplied end    (AddPostamble=1)
    unless exists $self->{Label};

  # Run base initialize
  $self->SUPER::initialize;

}

=back

=head2 Data Accessors

The following methods are provided for accessing instance data. These
methods should be used for accessing configuration parameters rather
than assuming the object is a hash.

Default values can be supplied by using these names as keys to a hash
of arguments when using the C<new()> constructor.

=over 4

=item B<AddPreamble>

Logical to control whether a C<latex> preamble is to be written.
If true, a valid C<latex> preamble is written before the pod data
is written.  This is similar to:

  \documentclass{article}
  \begin{document}

but will be more complicated if table of contents and indexing are required.
Can be used to set or retrieve the current value.

  $add = $parser->AddPreamble();
  $parser->AddPreamble(1);

If used in conjunction with C<AddPostamble> a full latex document will
be written that could be immediately processed by C<latex>.

=cut

sub AddPreamble {
   my $self = shift;
   if (@_) {
     $self->{AddPreamble} = shift;
   }
   return $self->{AddPreamble};
}

=item B<AddPostamble>

Logical to control whether a standard C<latex> ending is written to
the output file after the document has been processed.  In its
simplest form this is simply:

  \end{document}

but can be more complicated if an index is required.
Can be used to set or retrieve the current value.

  $add = $parser->AddPostamble();
  $parser->AddPostamble(1);

If used in conjunction with C<AddPreaamble> a full latex document will
be written that could be immediately processed by C<latex>.

=cut

sub AddPostamble {
   my $self = shift;
   if (@_) {
     $self->{AddPostamble} = shift;
   }
   return $self->{AddPostamble};
}

=item B<Head1Level>

The C<latex> sectioning level that should be used to correspond to
a pod C<=head1> directive. This can be used, for example, to turn
a C<=head1> into a C<latex> C<subsection>. This should hold a number
corresponding to the required position in an array containing the
following elements:

 [0] chapter
 [1] section
 [2] subsection
 [3] subsubsection
 [4] paragraph
 [5] subparagraph

Can be used to set or retrieve the current value:

  $parser->Head1Level(2);
  $sect = $parser->Head1Level;

Setting this number too high can result in sections that may not be
reproducible in the expected way. For example, setting this to 4 would
imply that C<=head3> do not have a corresponding C<latex> section
(C<=head1> would correspond to a C<paragraph>).

A check is made to ensure that the supplied value is an integer in the
range 0 to 5.

Default is for a value of 1 (i.e. a C<section>).

=cut

sub Head1Level {
   my $self = shift;
   if (@_) {
     my $arg = shift;
     if ($arg =~ /^\d$/ && $arg <= $#LatexSections) {
       $self->{Head1Level} = $arg;
     } else {
       carp "Head1Level supplied ($arg) must be integer in range 0 to ".$#LatexSections . "- Ignoring\n";
     }
   }
   return $self->{Head1Level};
}

=item B<Label>

This is the label that is prefixed to all C<latex> label and index
entries to make them unique. In general, pods have similarly titled
sections (NAME, DESCRIPTION etc) and a C<latex> label will be multiply
defined if more than one pod document is to be included in a single
C<latex> file. To overcome this, this label is prefixed to a label
whenever a label is required (joined with an underscore) or to an
index entry (joined by an exclamation mark which is the normal index
separator). For example, C<\label{text}> becomes C<\label{Label_text}>.

Can be used to set or retrieve the current value:

  $label = $parser->Label;
  $parser->Label($label);

This label is only used if C<UniqueLabels> is true.
Its value is set automatically from the C<NAME> field
if C<ReplaceNAMEwithSection> is true. If this is not the case
it must be set manually before starting the parse.

Default value is C<undef>.

=cut

sub Label {
   my $self = shift;
   if (@_) {
     $self->{Label} = shift;
   }
   return $self->{Label};
}

=item B<LevelNoNum>

Control the point at which C<latex> section numbering is turned off.
For example, this can be used to make sure that C<latex> sections
are numbered but subsections are not.

Can be used to set or retrieve the current value:

  $lev = $parser->LevelNoNum;
  $parser->LevelNoNum(2);

The argument must be an integer between 0 and 5 and is the same as the
number described in C<Head1Level> method description. The number has
nothing to do with the pod heading number, only the C<latex> sectioning.

Default is 2. (i.e. C<latex> subsections are written as C<subsection*>
but sections are numbered).

=cut

sub LevelNoNum {
   my $self = shift;
   if (@_) {
     $self->{LevelNoNum} = shift;
   }
   return $self->{LevelNoNum};
}

=item B<MakeIndex>

Controls whether C<latex> commands for creating an index are to be inserted
into the preamble and postamble

  $makeindex = $parser->MakeIndex;
  $parser->MakeIndex(0);

Irrelevant if both C<AddPreamble> and C<AddPostamble> are false
(or equivalently, C<UserPreamble> and C<UserPostamble> are set).

Default is for an index to be created.

=cut

sub MakeIndex {
   my $self = shift;
   if (@_) {
     $self->{MakeIndex} = shift;
   }
   return $self->{MakeIndex};
}

=item B<ReplaceNAMEwithSection>

This controls whether the C<NAME> section in the pod is to be translated
literally or converted to a slightly modified output where the section
name is the pod name rather than "NAME".

If true, the pod segment

  =head1 NAME

  pod::name - purpose

  =head1 SYNOPSIS

is converted to the C<latex>

  \section{pod::name\label{pod_name}\index{pod::name}}

  Purpose

  \subsection*{SYNOPSIS\label{pod_name_SYNOPSIS}%
               \index{pod::name!SYNOPSIS}}

(dependent on the value of C<Head1Level> and C<LevelNoNum>). Note that
subsequent C<head1> directives translate to subsections rather than
sections and that the labels and index now include the pod name (dependent
on the value of C<UniqueLabels>).

The C<Label> is set from the pod name regardless of any current value
of C<Label>.

  $mod = $parser->ReplaceNAMEwithSection;
  $parser->ReplaceNAMEwithSection(0);

Default is to translate the pod literally.

=cut

sub ReplaceNAMEwithSection {
   my $self = shift;
   if (@_) {
     $self->{ReplaceNAMEwithSection} = shift;
   }
   return $self->{ReplaceNAMEwithSection};
}

=item B<StartWithNewPage>

If true, each pod translation will begin with a C<latex>
C<\clearpage>.

  $parser->StartWithNewPage(1);
  $newpage = $parser->StartWithNewPage;

Default is false.

=cut

sub StartWithNewPage {
   my $self = shift;
   if (@_) {
     $self->{StartWithNewPage} = shift;
   }
   return $self->{StartWithNewPage};
}

=item B<TableOfContents>

If true, a table of contents will be created.
Irrelevant if C<AddPreamble> is false or C<UserPreamble>
is set.

  $toc = $parser->TableOfContents;
  $parser->TableOfContents(1);

Default is false.

=cut

sub TableOfContents {
   my $self = shift;
   if (@_) {
     $self->{TableOfContents} = shift;
   }
   return $self->{TableOfContents};
}

=item B<UniqueLabels>

If true, the translator will attempt to make sure that
each C<latex> label or index entry will be uniquely identified
by prefixing the contents of C<Label>. This allows
multiple documents to be combined without clashing 
common labels such as C<DESCRIPTION> and C<SYNOPSIS>

  $parser->UniqueLabels(1);
  $unq = $parser->UniqueLabels;

Default is true.

=cut

sub UniqueLabels {
   my $self = shift;
   if (@_) {
     $self->{UniqueLabels} = shift;
   }
   return $self->{UniqueLabels};
}

=item B<UserPreamble>

User supplied C<latex> preamble. Added before the pod translation
data. 

If set, the contents will be prepended to the output file before
the translated data regardless of the value of C<AddPreamble>.
C<MakeIndex> and C<TableOfContents> will also be ignored.

=cut

sub UserPreamble {
   my $self = shift;
   if (@_) {
     $self->{UserPreamble} = shift;
   }
   return $self->{UserPreamble};
}

=item B<UserPostamble>

User supplied C<latex> postamble. Added after the pod translation
data. 

If set, the contents will be prepended to the output file after
the translated data regardless of the value of C<AddPostamble>.
C<MakeIndex> will also be ignored.

=cut

sub UserPostamble {
   my $self = shift;
   if (@_) {
     $self->{UserPostamble} = shift;
   }
   return $self->{UserPostamble};
}

=begin __PRIVATE__

=item B<Lists>

Contains details of the currently active lists.
  The array contains C<Pod::List> objects. A new C<Pod::List>
object is created each time a list is encountered and it is
pushed onto this stack. When the list context ends, it 
is popped from the stack. The array will be empty if no
lists are active.

Returns array of list information in list context
Returns array ref in scalar context

=cut



sub lists {
  my $self = shift;
  return @{ $self->{_Lists} } if wantarray();
  return $self->{_Lists};
}

=end __PRIVATE__

=back

=begin __PRIVATE__

=head2 Subclassed methods

The following methods override methods provided in the C<Pod::Select>
base class. See C<Pod::Parser> and C<Pod::Select> for more information
on what these methods require.

=over 4

=cut

######### END ACCESSORS ###################

# Opening pod

=item B<begin_pod>

Writes the C<latex> preamble if requested.

=cut

sub begin_pod {
  my $self = shift;

  # Get the pod identification
  # This should really come from the '=head1 NAME' paragraph

  my $infile = $self->input_file;
  my $class = ref($self);
  my $date = gmtime(time);

  # Comment message to say where this came from
  my $comment = << "__TEX_COMMENT__";
%%  Latex generated from POD in document $infile
%%  Using the perl module $class
%%  Converted on $date
__TEX_COMMENT__

  # Write the preamble
  # If the caller has supplied one then we just use that

  my $preamble = '';
  if (defined $self->UserPreamble) {

    $preamble = $self->UserPreamble;

    # Add the description of where this came from
    $preamble .=  "\n$comment";
    

  } elsif ($self->AddPreamble) {
    # Write our own preamble

    # Code to initialise index making
    # Use an array so that we can prepend comment if required
    my @makeidx = (
		   '\usepackage{makeidx}',
		   '\makeindex',
		  );

    unless ($self->MakeIndex) {
      foreach (@makeidx) {
	$_ = '%% ' . $_;
      }
    }
    my $makeindex = join("\n",@makeidx) . "\n";


    # Table of contents
    my $tableofcontents = '\tableofcontents';
    
    $tableofcontents = '%% ' . $tableofcontents
      unless $self->TableOfContents;

    # Roll our own
    $preamble = << "__TEX_HEADER__";
\\documentclass{article}

$comment

$makeindex

\\begin{document}

$tableofcontents

__TEX_HEADER__

  }

  # Write the header (blank if none)
  $self->_output($preamble);

  # Start on new page if requested
  $self->_output("\\clearpage\n") if $self->StartWithNewPage;

}


=item B<end_pod>

Write the closing C<latex> code.

=cut

sub end_pod {
  my $self = shift;

  # End string
  my $end = '';

  # Use the user version of the postamble if deinfed
  if (defined $self->UserPostamble) {
    $end = $self->UserPostamble;

    $self->_output($end);

  } elsif ($self->AddPostamble) {

    # Check for index
    my $makeindex = '\printindex';

    $makeindex = '%% '. $makeindex  unless $self->MakeIndex;

    $end = "$makeindex\n\n\\end{document}\n";
  }


  $self->_output($end);

}

=item B<command>

Process basic pod commands.

=cut

sub command {
  my $self = shift;
  my ($command, $paragraph, $line_num, $parobj) = @_;

  # return if we dont care
  return if $command eq 'pod';

  # Store a copy of the raw text in case we are in a =for
  # block and need to preserve the existing latex
  my $rawpara = $paragraph;

  # Do the latex escapes
  $paragraph = $self->_replace_special_chars($paragraph);

  # Interpolate pod sequences in paragraph
  $paragraph = $self->interpolate($paragraph, $line_num);
  $paragraph =~ s/\s+$//;

  # Replace characters that can only be done after 
  # interpolation of interior sequences
  $paragraph = $self->_replace_special_chars_late($paragraph);

  # Now run the command
  if ($command eq 'over') {

    $self->begin_list($paragraph, $line_num);

  } elsif ($command eq 'item') {

    $self->add_item($paragraph, $line_num);

  } elsif ($command eq 'back') {

    $self->end_list($line_num);

  } elsif ($command eq 'head1') {

    # Store the name of the section
    $self->{_CURRENT_HEAD1} = $paragraph;

    # Print it
    $self->head(1, $paragraph, $parobj);

  } elsif ($command eq 'head2') {

    $self->head(2, $paragraph, $parobj);

  } elsif ($command eq 'head3') {

    $self->head(3, $paragraph, $parobj);

  } elsif ($command eq 'head4') {

    $self->head(4, $paragraph, $parobj);

  } elsif ($command eq 'head5') {

    $self->head(5, $paragraph, $parobj);

  } elsif ($command eq 'head6') {

    $self->head(6, $paragraph, $parobj);

  } elsif ($command eq 'begin') {

    # pass through if latex
    if ($paragraph =~ /^latex/i) {
      # Make sure that subsequent paragraphs are not modfied before printing
      $self->{_dont_modify_any_para} = 1;

    } else {
      # Suppress all subsequent paragraphs unless 
      # it is explcitly intended for latex
      $self->{_suppress_all_para} = 1;
    }

  } elsif ($command eq 'for') {

    # =for latex
    #   some latex

    # With =for we will get the text for the full paragraph
    # as well as the format name.
    # We do not get an additional paragraph later on. The next
    # paragraph is not governed by the =for

    # The first line contains the format and the rest is the
    # raw code.
    my ($format, $chunk) = split(/\n/, $rawpara, 2);

    # If we have got some latex code print it out immediately
    # unmodified. Else do nothing.
    if ($format =~ /^latex/i) {
      # Make sure that next paragraph is not modfied before printing
      $self->_output( $chunk );

    }

  } elsif ($command eq 'end') {

    # Reset suppression
    $self->{_suppress_all_para} = 0;
    $self->{_dont_modify_any_para} = 0;

  } elsif ($command eq 'pod') {

    # Do nothing

  } else {
    carp "Command $command not recognised at line $line_num\n";
  }

}

=item B<verbatim>

Verbatim text

=cut

sub verbatim {
  my $self = shift;
  my ($paragraph, $line_num, $parobj) = @_;

  # Expand paragraph unless in =begin block
  if ($self->{_dont_modify_any_para}) {
    # Just print as is
    $self->_output($paragraph);

  } else {

    return if $paragraph =~ /^\s+$/;

    # Clean trailing space
    $paragraph =~ s/\s+$//;

    # Clean tabs. Routine taken from Tabs.pm
    # by David Muir Sharnoff muir@idiom.com,
    # slightly modified by hsmyers@sdragons.com 10/22/01
    my @l = split("\n",$paragraph);
    foreach (@l) {
      1 while s/(^|\n)([^\t\n]*)(\t+)/
	$1. $2 . (" " x 
		  (8 * length($3)
		   - (length($2) % 8)))
	  /sex;
    }
    $paragraph = join("\n",@l);
    # End of change.



    $self->_output('\begin{verbatim}' . "\n$paragraph\n". '\end{verbatim}'."\n");
  }
}

=item B<textblock>

Plain text paragraph.

=cut

sub textblock {
  my $self = shift;
  my ($paragraph, $line_num, $parobj) = @_;

  # print Dumper($self);

  # Expand paragraph unless in =begin block
  if ($self->{_dont_modify_any_para}) {
    # Just print as is
    $self->_output($paragraph);

    return;
  }

  # Escape latex special characters
  $paragraph = $self->_replace_special_chars($paragraph);

  $paragraph =~ s!(?<=E<lt>)([\w.]+\@\w+(?:\.\w+)+)(?=E<gt>)!\\href{mailto:$1}{\\ttfamily $1}!g;

  # Interpolate interior sequences
  my $expansion = $self->interpolate($paragraph, $line_num);
  $expansion =~ s/\s+$//;

  # Escape special characters that can not be done earlier
  $expansion = $self->_replace_special_chars_late($expansion);

  # If we are replacing 'head1 NAME' with a section
  # we need to look in the paragraph and rewrite things
  # Need to make sure this is called only on the first paragraph
  # following 'head1 NAME' and not on subsequent paragraphs that may be
  # present.
  if ($self->{_CURRENT_HEAD1} =~ /^NAME/i && $self->ReplaceNAMEwithSection()) {

    # Strip white space from start and end
    $paragraph =~ s/^\s+//;
    $paragraph =~ s/\s$//;

    # Split the string into 2 parts
    my ($name, $purpose) = split(/\s+-\s+/, $expansion,2);

    # Now prevent this from triggering until a new head1 NAME is set
    $self->{_CURRENT_HEAD1} = '_NAME';

    # Might want to clear the Label() before doing this (CHECK)

    # Print the heading
    $self->head(1, $name, $parobj);

    # Set the labeling in case we want unique names later
    $self->Label( $self->_create_label( $name, 1 ) );

    # Raise the Head1Level by one so that subsequent =head1 appear
    # as subsections of the main name section unless we are already
    # at maximum [Head1Level() could check this itself - CHECK]
    $self->Head1Level( $self->Head1Level() + 1)
      unless $self->Head1Level == $#LatexSections;

    # Now write out the new latex paragraph
    $purpose = ucfirst($purpose);
    $self->_output("\n\n{\\Large\\sffamily\\slshape $purpose}\n\n");

  } else {
    # Just write the output
    $self->_output("\n\n$expansion\n\n");
  }

}

=item B<interior_sequence>

Interior sequence expansion

=cut

sub interior_sequence {
  my $self = shift;

  my ($seq_command, $seq_argument, $pod_seq) = @_;

  if( $seq_argument eq 'parse\_file' ) {
    print "$seq_command,$pod_seq\n";
  }

  if ($seq_command eq 'B') {
    return "{\\bfseries $seq_argument}";

  } elsif ($seq_command eq 'I') {
    return "{\\itshape $seq_argument}";

  } elsif ($seq_command eq 'E') {

    # If it is simply a number
    if ($seq_argument =~ /^\d+$/) {
      return chr($seq_argument);
    # Look up escape in hash table
    } elsif (exists $HTML_Escapes{$seq_argument}) {
      return $HTML_Escapes{$seq_argument};

    } else {
      my ($file, $line) = $pod_seq->file_line();
      warn "Escape sequence $seq_argument not recognised at line $line of file $file\n";
      return;
    }

  } elsif ($seq_command eq 'Z') {

    # Zero width space
    return '$\!$'; # '

  } elsif ($seq_command eq 'C') {
    return "{\\ttfamily $seq_argument}";

  } elsif ($seq_command eq 'F') {
    return "\\emph{$seq_argument}";

  } elsif ($seq_command eq 'S') {
    # non breakable spaces
    my $nbsp = '$\:$'; #'

    $seq_argument =~ s/\s/$nbsp/g;
    return $seq_argument;

  } elsif ($seq_command eq 'L') {

    my $link = Pod::Hyperlink->new($seq_argument);

    # undef on failure
    unless (defined $link) {
      carp $@;
      return;
    }

    # Handle internal links differently
    my $type = $link->type;
    my $page = $link->page;

    if ($type eq 'section' && $page eq '') {
      # Use internal latex reference 
      my $text = $link->text;

      # Convert to a label
      my $node = $self->_hyper_label($link->node);

      # return "\\S\\ref{$node}";
      my $page = '';
      if( $text =~ s/(\s+)elsewhere in this document$// ) {
        my $label = $self->_create_label($link->node);
        $page = "$1on page \\pageref{$label}";
      }

      return "\\hyperlink{$node}{$text}$page";

    } else {

      $seq_argument =~ m{^http://\w+(?:\.\w+)+}
        and return "\\href{$seq_argument}{\\ttfamily $seq_argument}";

      # Use default markup for external references
      # (although Starlink would use \xlabel)
      my $markup = $link->markup;

      my ($file, $line) = $pod_seq->file_line();

      return $self->interpolate($link->markup, $line);
    }
  } elsif ($seq_command eq 'P') {
    print "[$seq_argument]\n";
    if( exists $self->{KnownPODs}{$seq_argument} ) {
      my $link = Pod::Hyperlink->new($seq_argument);

      # undef on failure
      unless (defined $link) {
        carp $@;
        return;
      }

      # Use internal latex reference 
      my $text = $link->page;

      # Convert to a label
      my $node = $self->_hyper_label($link->page, 1);

      # return "\\S\\ref{$node}";
      return "\\hyperlink{$node}{\\emph{$text}}";
    }
    else {
      # Special markup for Pod::Hyperlink
      # Replace :: with / - but not sure if I want to do this
      # any more.
      my $link = $seq_argument;
      $link =~ s/::/\//g;

      my $ref = "\\href{http://search.cpan.org/perldoc?$seq_argument}{\\emph{$seq_argument}}";
      return $ref;
    }
  } elsif ($seq_command eq 'Q') {
    # Special markup for Pod::Hyperlink
    return "{\\sffamily $seq_argument}";

  } elsif ($seq_command eq 'X') {
    # Index entries

    # use \index command
    # I will let '!' go through for now
    # not sure how sub categories are handled in X<>
    my $index = $self->_create_index($seq_argument);
    return "\\index{$index}\n";

  } else {
    carp "Unknown sequence $seq_command<$seq_argument>";
  }

}

=back

=head2 List Methods

Methods used to handle lists.

=over 4

=item B<begin_list>

Called when a new list is found (via the C<over> directive).
Creates a new C<Pod::List> object and stores it on the 
list stack.

  $parser->begin_list($indent, $line_num);

=cut

sub begin_list {
  my $self = shift;
  my $indent = shift;
  my $line_num = shift;

  # Indicate that a list should be started for the next item
  # need to do this to work out the type of list
  push ( @{$self->lists}, Pod::List->new(-indent => $indent, 
					-start => $line_num,
					-file => $self->input_file,
				       )	 
       );

}

=item B<end_list>

Called when the end of a list is found (the C<back> directive).
Pops the C<Pod::List> object off the stack of lists and writes
the C<latex> code required to close a list.

  $parser->end_list($line_num);

=cut

sub end_list {
  my $self = shift;
  my $line_num = shift;

  unless (defined $self->lists->[-1]) {
    my $file = $self->input_file;
    warn "No list is active at line $line_num (file=$file). Missing =over?\n";
    return;
  }

  # What to write depends on list type
  my $type = $self->lists->[-1]->type;

  # Dont write anything if the list type is not set
  # iomplying that a list was created but no entries were
  # placed in it (eg because of a =begin/=end combination)
  $self->_output("\\end{$type}\n")
    if (defined $type && length($type) > 0);
  
  # Clear list
  pop(@{ $self->lists});

}

=item B<add_item>

Add items to the list. The first time an item is encountered 
(determined from the state of the current C<Pod::List> object)
the type of list is determined (ordered, unnumbered or description)
and the relevant latex code issued.

  $parser->add_item($paragraph, $line_num);

=cut

sub add_item {
  my $self = shift;
  my $paragraph = shift;
  my $line_num = shift;

  unless (defined $self->lists->[-1]) {
    my $file = $self->input_file;
    warn "List has already ended by line $line_num of file $file. Missing =over?\n";
    # Replace special chars
#    $paragraph = $self->_replace_special_chars($paragraph);
    $self->_output("$paragraph\n\n");
    return;
  }

  # If paragraphs printing is turned off via =begin/=end or whatver
  # simply return immediately
  return if $self->{_suppress_all_para};

  # Check to see whether we are starting a new lists
  if (scalar($self->lists->[-1]->item) == 0) {

    # Examine the paragraph to determine what type of list
    # we have
    $paragraph =~ s/\s+$//;
    $paragraph =~ s/^\s+//;

    my $type;
    if (substr($paragraph, 0,1) eq '*') {
      $type = 'itemize';
    } elsif ($paragraph =~ /^\d/) {
      $type = 'enumerate';
    } else {
      $type = 'description';
    }
    $self->lists->[-1]->type($type);

    $self->_output("\\begin{$type}\n");

  }

  my $type = $self->lists->[-1]->type;

  if ($type eq 'description') {
    # Handle long items - long items do not wrap
    # If the string is longer than 40 characters we split
    # it into a real item header and some bold text.
    my $maxlen = 40;
    my ($hunk1, $hunk2) = $self->_split_delimited( $paragraph, $maxlen );

    # Print the first hunk
    $self->_output("\n\\item[$hunk1] ");

    # and the second hunk if it is defined
    if ($hunk2) {
      $self->_output("\\textbf{$hunk2}");
    } else {
      # Not there so make sure we have a new line
      $self->_output("\\mbox{}");
    }

  } else {
    # If the item was '* Something' we still need to write
    # out the something
    my $extra_info = $paragraph;
    $extra_info =~ s/^\*\s*//;
    $self->_output("\n\\item $extra_info");
  }

  # Store the item name in the object. Required so that 
  # we can tell if the list is new or not
  $self->lists->[-1]->item($paragraph);

}

=back

=head2 Methods for headings

=over 4

=item B<head>

Print a heading of the required level.

  $parser->head($level, $paragraph, $parobj);

The first argument is the pod heading level. The second argument
is the contents of the heading. The 3rd argument is a Pod::Paragraph
object so that the line number can be extracted.

=cut

sub head {
  my $self = shift;
  my $num = shift;
  my $paragraph = shift;
  my $parobj = shift;

  # If we are replace 'head1 NAME' with a section
  # we return immediately if we get it
  return 
    if ($self->{_CURRENT_HEAD1} =~ /^NAME/i && $self->ReplaceNAMEwithSection());

  # Create a label
  my $label = $self->_create_label($paragraph);
  my $hyper = $self->_hyper_label($paragraph);

  # Create an index entry
  my $index = $self->_create_index($paragraph);

  # Work out position in the above array taking into account
  # that =head1 is equivalent to $self->Head1Level

  my $level = $self->Head1Level() - 1 + $num;

  # Warn if heading to large
  if ($num > $#LatexSections) {
    my $line = $parobj->file_line;
    my $file = $self->input_file;
    warn "Heading level too large ($level) for LaTeX at line $line of file $file\n";
    $level = $#LatexSections;
  }

  # Check to see whether section should be unnumbered
  my $star = ($level >= $self->LevelNoNum ? '*' : '');

  $paragraph =~ s/\\char95\{\}/\\_/g;

  my $lcpar = $paragraph;
  if ($lcpar !~ /[a-z]/) {
    $lcpar =~ s/(^|\s)([^_\W])([^_\W]+)(?=$|\s)/$1$2\L$3/g;
  }

  my $lcparb = $level >= $self->LevelNoNum ? '' : "[$lcpar]";

  # Section
  $self->_output("\\" .$LatexSections[$level] .$star ."${lcparb}{\\hypertarget{".$hyper."}{$lcpar}\\label{".$label ."}\\index{".$index."}}\n");

}


=back

=end __PRIVATE__

=begin __PRIVATE__

=head2 Internal methods

Internal routines are described in this section. They do not form part of the
public interface. All private methods start with an underscore.

=over 4

=item B<_output>

Output text to the output filehandle. This method must be always be called
to output parsed text.

   $parser->_output($text);

Does not write anything if a =begin is active that should be
ignored.

=cut

sub _output { 
  my $self = shift;
  my $text = shift;

  print { $self->output_handle } $text
    unless $self->{_suppress_all_para};

}


=item B<_replace_special_chars>

Subroutine to replace characters that are special in C<latex>
with the escaped forms

  $escaped = $parser->_replace_special_chars($paragraph);

Need to call this routine before interior_sequences are munged but not
if verbatim. It must be called before interpolation of interior
sequences so that curly brackets and special latex characters inserted
during interpolation are not themselves escaped. This means that < and
> can not be modified here since the text still contains interior
sequences.

Special characters and the C<latex> equivalents are:

  }     \}
  {     \{
  _     \_
  $     \$
  %     \%
  &     \&
  \     $\backslash$
  ^     \^{}
  ~     \~{}

=cut

sub _replace_special_chars {
  my $self = shift;
  my $paragraph = shift;

  # Replace a \ with $\backslash$
  # This is made more complicated because the dollars will be escaped
  # by the subsequent replacement. Easiest to add \backslash 
  # now and then add the dollars
  $paragraph =~ s/\\/\\backslash/g;

  # Must be done after escape of \ since this command adds latex escapes
  # Replace characters that can be escaped
  $paragraph =~ s/([\$\#&%{}])/\\$1/g;
  $paragraph =~ s/([\[])/\\lbrack{}/g;
  $paragraph =~ s/([\]])/\\rbrack{}/g;
  $paragraph =~ s/_/\\char95{}/g;

  # Replace ^ characters with \^{} so that $^F works okay
  $paragraph =~ s/(\^)/\\$1\{\}/g;

  # Replace tilde (~) with \texttt{\~{}}
  $paragraph =~ s/~/\\texttt\{\\~\{\}\}/g;

  # Now add the dollars around each \backslash
  $paragraph =~ s/(\\backslash)/\$$1\$/g;
  return $paragraph;
}

=item B<_replace_special_chars_late>

Replace special characters that can not be replaced before interior
sequence interpolation. See C<_replace_special_chars> for a routine
to replace special characters prior to interpolation of interior
sequences.

Does the following transformation:

  <   $<$
  >   $>$
  |   $|$


=cut

sub _replace_special_chars_late {
  my $self = shift;
  my $paragraph = shift;

  # < and >
  $paragraph =~ s/(<|>)/\$$1\$/g;

  # Replace | with $|$
  $paragraph =~ s'\|'$|$'g;


  return $paragraph;
}


=item B<_create_label>

Return a string that can be used as an internal reference
in a C<latex> document (i.e. accepted by the C<\label> command)

 $label = $parser->_create_label($string)

If UniqueLabels is true returns a label prefixed by Label()
This can be suppressed with an optional second argument.

 $label = $parser->_create_label($string, $suppress);

If a second argument is supplied (of any value including undef)
the Label() is never prefixed. This means that this routine can
be called to create a Label() without prefixing a previous setting.

=cut

sub _create_label {
  my $self = shift;
  my $paragraph = shift;
  my $suppress = (@_ ? 1 : 0 );

  # Remove latex commands
  $paragraph = $self->_clean_latex_commands($paragraph);

  # Remove non alphanumerics from the label and replace with underscores
  # want to protect '-' though so use negated character classes 
  $paragraph =~ s/[^-:\w]/_/g;

  # Multiple underscores will look unsightly so remove repeats
  # This will also have the advantage of tidying up the end and
  # start of string
  $paragraph =~ s/_+/_/g;

  # If required need to make sure that the label is unique
  # since it is possible to have multiple pods in a single
  # document
  if (!$suppress && $self->UniqueLabels() && defined $self->Label) {
    $paragraph = $self->Label() .'_'. $paragraph;
  }

  return $paragraph;
}

sub _hyper_label {
  my $self = shift;
  my $paragraph = shift;
  my $suppress = (@_ ? 1 : 0 );

  # Remove latex commands
  $paragraph = $self->_clean_latex_commands($paragraph);

  # Remove non alphanumerics from the label and replace with underscores
  # want to protect '-' though so use negated character classes 
  $paragraph =~ s/[^-:\w]/_/g;

  # Multiple underscores will look unsightly so remove repeats
  # This will also have the advantage of tidying up the end and
  # start of string
  $paragraph =~ s/_+/_/g;

  # If required need to make sure that the label is unique
  # since it is possible to have multiple pods in a single
  # document
  if (!$suppress && $self->UniqueLabels() && defined $self->Label) {
    $paragraph = $self->Label() .'_'. $paragraph;
  }

  $paragraph =~ s/[:_]+//g;

  return $paragraph;
}


=item B<_create_index>

Similar to C<_create_label> except an index entry is created.
If C<UniqueLabels> is true, the index entry is prefixed by 
the current C<Label> and an exclamation mark.

  $ind = $parser->_create_index($paragraph);

An exclamation mark is used by C<makeindex> to generate 
sub-entries in an index.

=cut

sub _create_index {
  my $self = shift;
  my $paragraph = shift;
  my $suppress = (@_ ? 1 : 0 );

  # Remove latex commands
  $paragraph = $self->_clean_latex_commands($paragraph);

  # If required need to make sure that the index entry is unique
  # since it is possible to have multiple pods in a single
  # document
  if (!$suppress && $self->UniqueLabels() && defined $self->Label) {
    $paragraph = $self->Label() .'!'. $paragraph;
  }

  # Need to replace _ with space
  $paragraph =~ s/_/ /g;

  return $paragraph;

}

=item B<_clean_latex_commands>

Removes latex commands from text. The latex command is assumed to be of the
form C<\command{ text }>. "C<text>" is retained

  $clean = $parser->_clean_latex_commands($text);

=cut

sub _clean_latex_commands {
  my $self = shift;
  my $paragraph = shift;

  # Remove latex commands of the form \text{ }
  # and replace with the contents of the { }
  # need to make this non-greedy so that it can handle
  #  "\text{a} and \text2{b}"
  # without converting it to
  #  "a} and \text2{b"
  # This match will still get into trouble if \} is present 
  # This is not vital since the subsequent replacement of non-alphanumeric
  # characters will tidy it up anyway
  $paragraph =~ s/\\\w+{(.*?)}/$1/g;
  $paragraph =~ s/\\\w+\s//g;

  return $paragraph
}

=item B<_split_delimited>

Split the supplied string into two parts at approximately the
specified word boundary. Special care is made to make sure that it
does not split in the middle of some curly brackets.

e.g. "this text is \textbf{very bold}" would not be split into
"this text is \textbf{very" and " bold".

  ($hunk1, $hunk2) = $self->_split_delimited( $para, $length);

The length indicates the maximum length of hunk1.

=cut

# initially Supplied by hsmyers@sdragons.com
# 10/25/01, utility to split \hbox
# busting lines. Reformatted by TimJ to match module style.
sub _split_delimited {
  my $self = shift;
  my $input = shift;
  my $limit = shift;

  # Return immediately if already small
  return ($input, '') if length($input) < $limit;

  my @output;
  my $s = '';
  my $t = '';
  my $depth = 0;
  my $token;

  $input =~ s/\n/ /gm;
  $input .= ' ';
  foreach ( split ( //, $input ) ) {
    $token .= $_;
    if (/\{/) {
      $depth++;
    } elsif ( /}/ ) {
      $depth--;
    } elsif ( / / and $depth == 0) {
      push @output, $token if ( $token and $token ne ' ' );
      $token = '';
    }
  }

  foreach  (@output) {
    if (length($s) < $limit) {
      $s .= $_;
    } else {
      $t .= $_;
    }
  }

  # Tidy up
  $s =~ s/\s+$//;
  $t =~ s/\s+$//;
  return ($s,$t);
}

=back

=end __PRIVATE__

=head1 NOTES

Compatible with C<latex2e> only. Can not be used with C<latex> v2.09
or earlier.

A subclass of C<Pod::Select> so that specific pod sections can be
converted to C<latex> by using the C<select> method.

Some HTML escapes are missing and many have not been tested.

=head1 SEE ALSO

L<Pod::Parser>, L<Pod::Select>, L<pod2latex>

=head1 AUTHORS

Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>

Bug fixes have been received from: Simon Cozens
E<lt>simon@cozens.netE<gt>, Mark A. Hershberger
E<lt>mah@everybody.orgE<gt>, Marcel Grunauer
E<lt>marcel@codewerk.comE<gt> and Hugh S Myers
E<lt>hsmyers@sdragons.comE<gt>.

=head1 COPYRIGHT

Copyright (C) 2000-2001 Tim Jenness. All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=begin __PRIVATE__

=head1 REVISION

$Id: MyLaTeX.pm 5 2006/01/04 22:24:50 +0000 mhx $

=end __PRIVATE__

=cut
