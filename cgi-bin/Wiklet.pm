# Wiklet (c) 2002-2021 Reuben Thomas (rrt@sc3d.org)
# https://rrt.sc3d.org/Software/Wiklet
# Distributed under the GNU General Public License version 3,
# or, at your option, any later version.

require 5.8.4;
package Wiklet;

use strict;
use warnings;

use Encode;
use File::Basename;
use File::stat;
use POSIX 'strftime';
use Cwd qw(abs_path);

use CGI ':standard';
use CGI::Carp 'fatalsToBrowser';
use Perl6::Slurp;
use File::Which;

use RRT::Misc;
use RRT::Macro 3.10;


# Config vars
use vars qw($BaseUrl $ScriptUrl $PrettyUrls $HomePage $DocumentRoot
            $Recent %Macros %Actions);

# Computed globals
use vars qw($BrowseUrl $TextDir $TemplateDir $CVSRoot $Header
            $Action $Template $Text %Cache);


# Macros

%Macros =
  (
   # Variables
   action => sub {$Action},
   template => sub {$Template},
   text => sub {$Text},
   scripturl => sub {$ScriptUrl},
   homepage => sub {$HomePage},

   page => sub {
     return escapePage($Macros{pagename}());
   },


   # Macros

   lastmodified => sub {
     my $time = pageMTime($Macros{pagename}());
     return strftime("%Y/%m/%d", localtime $time);
   },

   url => sub {
     my ($path) = @_;
     return $BaseUrl . $path;
   },

   browse => sub {
     my ($page) = @_;
     return $BrowseUrl . escapePage($page);
   },

   recentchanges => sub {
     our @depFiles;
     push @depFiles, $TextDir; # invalidate cache when any page is changed
     my $now = time;
     my $limit = $now - ($now % 86400) - ($Recent * 86400);
     my (%changes, $result);
     foreach (getIndex()) {
       my $time = pageMTime($_);
       push @{$changes{$time - ($time % 86400)}}, "$_" if $time >= $limit;
     }
     $result .= strftime("%d %B", localtime $_) . "\n---\n\n   *" .
       (join "\n   *",
        (map {" [" . unescapePage($_) . "]"} @{$changes{$_}})) . "\n\n"
          foreach (sort {$b <=> $a} keys %changes);
     return "\n" . $result . "\n";
   },

   include => sub {
     my ($file) = @_;
     our @depFiles;
     push @depFiles, "$TemplateDir/$file";
     return expand(getTemplate($file), \%Macros);
   },

   canonicalpath => sub {
     my ($file) = @_;
     return "$DocumentRoot/$file";
   },

   link => sub {
     my ($url, $desc) = @_;
     $desc = $url if !$desc || $desc eq "";
     return a({-href => $url}, $desc);
   },

   filesize => sub {
     my ($file) = @_;
     $file = $Macros{canonicalpath}($file);
     our @depFiles;
     push @depFiles, $file;
     return numberToSI(-s $file || 0) . "b";
   },

   image => sub {
     my ($image, $alt, $width, $height) = @_;
     return "" if $image !~ /(gif|jpg|jpeg|png|bmp)$/;
     $image = $Macros{url}($Macros{canonicalpath}("image/$image")) if $image !~ /^http:/;
     my %attr = ("-src" => $image);
     $attr{-alt} = $alt if $alt;
     $attr{-width} = $width if $width;
     $attr{-height} = $height if $height;
     return img \%attr;
   },

   webfile => sub {
     my ($path, $format) = @_;
     $path = "download/$path";
     my $file = $Macros{canonicalpath}($path);
     our @depFiles;
     push @depFiles, $file;
     my $size = $Macros{filesize}($path);
     return $Macros{link}($Macros{url}($path), $format) . " $size";
   },

   counter => sub {
     our $page;
     my ($countPage) = @_;
     my $count = readPage($countPage);
     $count += 1;
     writePage($countPage, $count); # as a side-effect, this defeats caching for the page
     return $count;
   },
  );


# Rendering

sub escapePage {
  my ($page) = @_;
  $page ||= "";
  $page =~ s/([^-0-9a-zA-Z. ])/sprintf "=%X=", ord $1/ge;
  $page =~ s/ /_/g;
  return $page;
}

sub unescapePage {
  my ($page) = @_;
  $page ||= "";
  $page =~ s/=([0-9A-F]+)=/chr (hex $1)/ge;
  $page =~ s/_/ /g;
  return $page;
}

# Turn entities into characters
sub expandNumericEntities {
  my ($text) = @_;
  $text =~ s/&#(\pN+);/chr($1)/ge;
  return $text;
}

# Render Markdown to HTML
sub renderMarkdown {
  my ($file) = @_;
  open(READER, "-|:utf8", "markdown", "-base", $BaseUrl, "-f", "autolink", $file);
  my $text = scalar(slurp \*READER);
  # Pull out the body element of the HTML
  $text =~ m|<body[^>]*>(.*)</body>|gsmi;
  # Render local links
  $text =~ s|\[([^]]*)\]|a({-href => $BrowseUrl . escapePage($1)}, $1)|gsme;
  return expandNumericEntities($text);
}


# Reading and writing pages

sub pageToFile {
  my ($page) = @_;
  my $file = "$TextDir/" . escapePage($page) . ".md";
  return $file;
}

sub pageLocked {
  my ($page) = @_;
  my $file = pageToFile($page);
  return (-f $file) ? !(-w $file) : 0;
}

sub pageMTime {
  my ($page) = @_;
  my $file = pageToFile($page);
  return 0 unless -f $file; # Ignore objects that aren't files
  return stat($file)->mtime || 0;
}

sub readPage {
  my ($page) = @_;
  my $file = pageToFile($page);
  return "" unless -f $file;
  return scalar(slurp '<:utf8', $file);
}

sub getTemplateName {
  my ($file) = @_;
  $Template = $file;
  return "$TemplateDir/$Template";
}

sub getTemplate {
  my ($file) = @_;
  my $text = scalar(slurp '<:utf8', getTemplateName($file));
  return $text if defined $text;
  # Avoid infinite loop in getTemplate if file missing
  return expand(renderMarkdown("$TemplateDir/nofile.md"), \%Macros);
}

sub dirty {
  my ($page)= @_;
  foreach (@{$Cache{$page}{depfiles}}) {
    return 1 if ($Cache{$page}{mtime} != (stat($_)->mtime or 0));
  }
  return 0;
}

sub checkCVS {
  abortScript("", expand(renderMarkdown(getTemplateName("nocvs.md")), \%Macros))
    if !which("cvs");
}

sub checkMarkdown {
  abortScript("", expand(getTemplateName("nomarkdown.htm"), \%Macros))
    if !which("markdown");
}

sub getHtml {
  my ($page) = @_;
  my $file = pageToFile($page);
  return $Cache{$page}{text}
    if defined $Cache{$page} && !dirty($page);
  $file = -f $file ? $file : "$TemplateDir/newpage.md";
  $Text = renderMarkdown($file);
  our @depFiles = pageToFile($page);
  my $tmpl = expandNumericEntities(getTemplate("view.htm"));
  $tmpl = expand($tmpl, \%Macros);
  $Cache{$page} = {text => $tmpl,
                   mtime => (stat($file)->mtime or 0),
                   depfiles => [@depFiles]}
    if -f $file;
  return $tmpl;
}

sub checkInFile {
  my ($file, $text) = @_;
  my $new = ! -f $file;
  use File::Slurp; # for write_file
  write_file($file, $text);
  system "cvs add -m \"Add file\" $file 2>/dev/null 1>&2"
    if $new;
  system "cvs ci -m \"\" $file 2>/dev/null 1>&2";
}

sub writePage {
  my ($page, $text) = @_;
  $text =~ s/\r//g;             # get rid of CRs
  my $oldText = readPage($page);
  my $file = pageToFile($page);
  checkInFile($file, $text) if $oldText ne $text;
  touch($TextDir);              # for cache invalidation
}

sub movePage {
  my ($page, $newPage) = @_;
  my $newFile = pageToFile($newPage);
  abortScript($newPage, renderMarkdown(getTemplateName("pageexists.md")))
    if -f $newFile;
  my $file = pageToFile($page);
  if ($newPage ne "") {
    my $text = "";
    $text = scalar(slurp '<:utf8', $file) if -f $file; # old page might not exist!
    checkInFile($newFile, $text);
    $Macros{pagename} = sub {$newPage};
    checkInFile($file, expand(getTemplate("pagemoved.md"), \%Macros));
  } else {                      # we are deleting the old page
    system "cvs rm -f $file 2>/dev/null 1>&2";
    system "cvs ci -m \"\" $file 2>/dev/null 1>&2";
  }
}

sub getIndex {
  my @index;
  while (my $file = <$TextDir/*>) {
    my $page = unescapePage(basename(untaint($file)));
    # filter out directories (. .. and CVS)
    push @index, $page if -f $file;
  }
  return @index;
}


# Actions

sub abortScript {
  my ($page, $msg) = @_;
  $Macros{pagename} = sub {$page};
  $Text = expand($msg, \%Macros);
  my $tmpl = expandNumericEntities(getTemplate("abort.htm"));
  $tmpl = expand($tmpl, \%Macros);
  print $Header . $tmpl;
  exit;
}

sub getParam {
  my ($name) = @_;
  my $var = param($name);
  return if !defined $var;
  return decode_utf8(untaint($var));
}

sub doRequest {
  my ($page) = @_;
  binmode(STDOUT, ":raw"); # FIXME: This is a kludge to make UTF-8 output work
  $BrowseUrl = $PrettyUrls ? $BaseUrl : "$ScriptUrl?page=";
  $TextDir = "$DocumentRoot/text";
  $TemplateDir = "$DocumentRoot/template";
  $CVSRoot = scalar(slurp '<:utf8', "$TextDir/CVS/Root");
  chomp $CVSRoot;
  $ENV{CVSROOT} = $CVSRoot;
  $page ||= unescapePage(getParam("page"));
  $page = $HomePage
    if !defined $page || $page eq "";
  $Macros{pagename} = sub {$page};
  $Header = header(-type => "text/html; charset=utf-8",
                   -expires => "now");
  $Action = getParam("action") || "view";
  abortScript($page, renderMarkdown(getTemplateName("noaction.md")))
    unless $Actions{$Action};
  checkMarkdown();
  checkCVS();
  print $Header . $Actions{$Action}();
}

%Actions =
  (
   view => sub {
     return getHtml($Macros{pagename}());
   },

   edit => sub {
     my $tmpl = expandNumericEntities(getTemplate("edit.htm"));
     abortScript($Macros{pagename}(), renderMarkdown(getTemplateName("readonly.md")))
       if pageLocked($Macros{pagename}());
     my $text = readPage($Macros{pagename}());
     $text =~ s/&/&amp;/g;
     $text =~ s/</&lt;/g;
     $text =~ s/>/&gt;/g;
     $tmpl = expand($tmpl, \%Macros);
     $tmpl =~ s/\$TEXT/$text/g;
     return $tmpl;
   },

   save => sub {
     writePage($Macros{pagename}(), getParam("text") || "");
     my $newPage = getParam("pagename") || "";
     movePage($Macros{pagename}(), $newPage) if $newPage ne $Macros{pagename}();
     my $url = escapePage($newPage);
     $Header = "";
     return redirect("$BrowseUrl$url");
   },
  );


1;                              # return a true value
