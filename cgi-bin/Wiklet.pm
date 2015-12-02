# Wiklet (c) 2002-2015 Reuben Thomas (rrt@sc3d.org)
# http://rrt.sc3d.org/Software/Wiklet
# Distributed under the GNU General Public License version 3,
# or, at your option, any later version.

require 5.8.4;
package Wiklet;

use strict;
use warnings;

use Encode;
use CGI ':standard';
use CGI::Carp 'fatalsToBrowser';
use File::Basename;
use File::stat;
use POSIX 'strftime';
use Cwd qw(abs_path);

use Perl6::Slurp;

use RRT::Misc;
use RRT::Macro;


# Config vars
use vars qw($ServerUrl $BaseUrl $ScriptUrl $PrettyUrls $HomePage $DocumentRoot
            $Recent %Macros %Actions);

# Computed globals
use vars qw($BrowseUrl $TextDir $TemplateDir $CVSRoot $Header
            $Action $Template $Text $UndefMacro %Cache);


# Redefine RRT::Misc normalize
# FIXME: sort this out!
# Normalize $file, relative to optional $currentDir (or "/" if not given); restrict to $rootDir
use Cwd 'realpath';
sub normalizePath {
  my ($file, $currentDir, $rootDir) = @_;
  if (!defined($rootDir)) {
    $rootDir = $currentDir || "/";
    $currentDir = "/";
  }
  my $path = (fileparse($currentDir))[1] if $currentDir && $currentDir ne "";
  $path ||= "/";
  $file = "$path$file" if $file !~ m|^/|;
  $file =~ s|^\./||;
  my $realfile = realpath($file);
  return "" if $realfile !~ /^$rootDir/;
  return $file;
}


# Macros

%Macros =
  (
   # Variables
   action => sub {$Action},
   template => sub {$Template},
   text => sub {$Text},
   undefmacro => sub {$UndefMacro},
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
     return "$BaseUrl" . (normalizePath($path || "", "/", $DocumentRoot));
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
     push @depFiles, $Macros{canonicalpath}("$TemplateDir/$file");
     return getTemplate($file);
   },

   canonicalpath => sub {
     my ($file) = @_;
     return "/" . normalizePath($file, "/", $DocumentRoot);
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
     my ($file, $format) = @_;
     $file = $Macros{canonicalpath}("download/$file");
     our @depFiles;
     push @depFiles, $file;
     my $size = $Macros{filesize}($file);
     return $Macros{link}($Macros{url}($file), $format) . " $size";
   },

   pdfpages => sub {
     my ($file) = @_;
     $file = $Macros{canonicalpath}("download/$file");
     my $n = `pdfinfo "$file"`;
     $n =~ /Pages:\s*(\pN+)/;
     return $1 . ($1 eq "1" ? "p." : "pp.");
   },

   pdffile => sub {
     our @depFiles;
     my ($file) = @_;
     $file = $Macros{canonicalpath}("download/$file");
     push @depFiles, $file;
     return $Macros{link}($Macros{url}($file), "PDF") . " " . $Macros{pdfpages}($file);
   },

   pdfdoc => sub {
     my ($file, $title, $comment) = @_;
     $comment ||= "";
     return em($title) . " ($comment" . $Macros{pdffile}($file) . ")";
   },

   webdoc => sub {
     my ($file, $title, $comment) = @_;
     return $Macros{pdfdoc}($file, em(internalLink($title)), $comment);
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

sub internalLink {
  my ($page, $desc) = @_;
  my $url = escapePage($page);
  $desc = $page if !$desc || $desc eq "";
  return a({-href => "$BrowseUrl$url"}, $desc);
}

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

# Render smut to HTML
sub renderSmutHTML {
  my ($file) = @_;
  my $text = renderSmut($file, "smut-html.pl");
  # Pull out the body element of the HTML
  $text =~ m|<body[^>]*>(.*)</body>|gsmi;
  return $1;
}

# Render smut
sub renderSmut {
  my ($file, $renderer) = @_;
  my $script = untaint(abs_path($renderer));
  open(READER, "-|:utf8", $script, $file, $Macros{pagename}(), $BaseUrl, $DocumentRoot);
  return scalar(slurp \*READER);
}


# Reading and writing pages

sub pageToFile {
  my ($page) = @_;
  my $file = "$TextDir/" . escapePage($page);
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
  return stat($file)->mtime or 0;
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
  return $Macros{canonicalpath}("$TemplateDir/$Template");
}

sub getTemplate {
  my ($file) = @_;
  my $text = scalar(slurp '<:utf8', getTemplateName($file));
  return $text if defined $text;
  # Avoid infinite loop in getTemplate if file missing
  return expand(renderSmutHTML($Macros{canonicalpath}("$TemplateDir/nofile.txt")));
}

sub dirty {
  my ($page)= @_;
  foreach (@{$Cache{$page}{depfiles}}) {
    return 1 if ($Cache{$page}{mtime} != (stat($_)->mtime or 0));
  }
  return 0;
}

sub checkCVS {
  abortScript("", expand(renderSmutHTML(getTemplateName("nocvs.txt"))))
    if !which("cvs");
}

sub getHtml {
  my ($page) = @_;
  my $file = pageToFile($page);
  return $Cache{$page}{text}
    if defined $Cache{$page} && !dirty($page);
  $file = -f $file ? $file : "$TemplateDir/newpage.txt";
  $Text = renderSmutHTML($file);
  our @depFiles = pageToFile($page);
  my $tmpl = getTemplate("view.htm");
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
  abortScript($newPage, renderSmutHTML(getTemplateName("pageexists.txt")))
    if -f $newFile;
  my $file = pageToFile($page);
  if ($newPage ne "") {
    my $text = "";
    $text = scalar(slurp '<:utf8', $file) if -f $file; # old page might not exist!
    checkInFile($newFile, $text);
    $Macros{pagename} = sub {$newPage};
    checkInFile($file, expand(getTemplate("pagemoved.txt"), \%Macros));
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
  $Text = $msg;
  my $tmpl = getTemplate("abort.htm");
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
  binmode(STDOUT, ":utf8");
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
  abortScript($page, renderSmutHTML(getTemplateName("noaction.txt")))
    unless $Actions{$Action};
  checkCVS();
  print $Header . $Actions{$Action}();
}

%Actions =
  (
   view => sub {
     return getHtml($Macros{pagename}());
   },

   wiki => sub {
     return renderSmut(pageToFile($Macros{pagename}()), "smut-txt.pl");
   },

   edit => sub {
     my $tmpl = getTemplate("edit.htm");
     abortScript($Macros{pagename}(), renderSmutHTML(getTemplateName("readonly.txt")))
       if pageLocked($Macros{pagename}());
     my $text = readPage($Macros{pagename}());
     $text =~ s/&/&amp;/g;
     $text =~ s/</&lt;/g;
     $text =~ s/>/&gt;/g;
     $tmpl = expand($tmpl, \%Macros);
     $tmpl =~ s/\$tEXT/$text/g; # First letter of $TEXT is lower-cased by expand()
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
