#!/usr/bin/perl -Tw
# Wiklet (c) 2002-2004 Reuben Thomas (rrt@sc3d.org; http://rrt.sc3d.org)
# Distributed under the GNU General Public License

$ENV{PATH}  = '/bin:/usr/bin';
use strict;
use lib ".";
use CGI qw(:standard);
use Wiklet;


# Configuration

# Root of Wiki relative to root of site
$Wiklet::BaseUrl = "/~user/";
# Relative URL of CGI script to run Wiki
$Wiklet::ScriptUrl = "/cgi-bin/wiki.pl";
# Uncomment next line if URL rewriting configured to map
# ${BaseUrl}/Foo to ${ScriptUrl}?page=Foo
#$Wiklet::PrettyUrls = 1;
# Home page (default if none given)
$Wiklet::HomePage = "Home Page";
# Directory of Wiki in file system
$Wiklet::DocumentRoot = "/home/user/public_html";
# Number of days back to go for recent changes
$Wiklet::Recent = "14";

# Extra macros
# $Wiklet::Macros{email} = sub {
#   my ($text) = @_;
#   return $Wiklet::Macros{link}("mailto:rrt\@sc3d.org", "$text");
# };

# Create new files world-writable to allow editing by the web server
#umask 0000;


# Perform the request
Wiklet::doRequest();
