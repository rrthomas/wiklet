# Wiklet Installation

In order to run [Wiklet], you need access to a web server capable of running [Perl](https://www.perl.org) CGI scripts (Perl 5.10 or later), [CVS](https://www.nongnu.org/cvs), and [discount](https://www.pell.portland.or.us/~orc/Code/discount/). If you're not sure what some of that means, Wiklet is probably tricky for you to install (sorry!), and you should seek help (e.g. learn about web servers and CGI scripts, or ask the person who runs your web server for help).

To install Wiklet:

1. Unpack the [distribution archive](Getting Wiklet).
2. Copy the contents of the `cgi-bin` directory into the CGI program directory of your web server.
3. Create a new CVS repository with the command `CVSROOT=_<path>_ cvs init`. See the [CVS manual](https://www.gnu.org/software/trans-coord/manual/cvs/) for a full guide to CVS. The entire repository must be writable by CGI programs.
4. In the `text` subdirectory of the Wiklet sources, run the command `CVSROOT=_<path>_ cvs import -m "Initial import" www wiki start` to create the Wiki's CVS module. `www` is the module name and can be whatever you like.
5. Now delete all the files in `text`; then, check them out from CVS using the command `CVSROOT=_<path>_ cvs co -d . www`.
6. Make all the files in `text` and in the CVS repository writable by CGI programs.
7. Configure the `wiki.pl` script as described in [Wiklet Configuration].
8. Copy the `template` and `text` directories to the location specified in `DocumentRoot` (see [Wiklet Configuration]). Directories called `download` and `image` should be created in the same place for downloadable files and local images respectively. The `text` directory must be writable by CGI programs (Wiklet saves HTML versions of the Wiki pages there) but the others need not be.
9. The Wiki should now be ready to use. See [Wiklet Customization] for details of the various ways in which [Wiklet] can be customized.

See [Wiklet Organisation] for more details of the layout of the files and URLs used by Wiklet.
