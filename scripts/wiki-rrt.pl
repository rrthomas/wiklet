#! /usr/bin/speedy -Tw
# Wiklet (c) 2002-2005 Reuben Thomas (rrt@sc3d.org; http://rrt.sc3d.org)
# Distributed under the GNU General Public License

$ENV{PATH}  = '/bin:/usr/bin';
use strict;
use lib ".";
use CGI qw(:standard);
use Wiklet;


# Configuration

# Root of Wiki relative to root of site
$Wiklet::BaseUrl = "/";
# Relative URL of CGI script to run Wiklet
$Wiklet::ScriptUrl = "/cgi-bin/wiklet.pl";
# Uncomment next line if URL rewriting configured to map
# ${BaseUrl}/Foo to ${ScriptUrl}?page=Foo
$Wiklet::PrettyUrls = 1;
# Home page (default if none given)
$Wiklet::HomePage = "Reuben Thomas";
# Directory of Wiki in file system
$Wiklet::DocumentRoot = "/home/rrt/public_html";
# Number of days back to go for recent changes
$Wiklet::Recent = "32";

# Extra macros
$Wiklet::Macros{email} = sub {
  my ($text) = @_;
  return $Wiklet::Macros{link}("mailto:rrt\@sc3d.org", "$text");
};

$Wiklet::Macros{musicfile} = sub {
  my ($file, $title, $comment) = @_;
  $comment = "" if !$comment;
  return em($title) . " ($comment" .
    $Wiklet::Macros{webfile}("music/$file.sib", "Sibelius") . ", " .
      $Wiklet::Macros{pdffile}("music/$file.pdf") . ", " .
        $Wiklet::Macros{webfile}("music/$file.mid", "MIDI") . ")";
};

$Wiklet::Macros{photo} = sub {
  my ($file, $thumb, $comment) = @_;
  $comment = "" if !$comment;
  return $Wiklet::Macros{link}($Wiklet::Macros{url}("image/$file"), $Wiklet::Macros{image}($thumb)) . $comment;
};

# Create new files world-writable to allow editing by the web server
umask 0000;


# Perform the request
Wiklet::doRequest();
