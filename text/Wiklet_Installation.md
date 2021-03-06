# Wiklet Installation

In order to run [Wiklet], you need access to a web server capable of running [Perl](https://www.perl.org) CGI scripts (Perl 5.10 or later), [Git](https://git-scm.com), and [discount](https://www.pell.portland.or.us/~orc/Code/discount/). If you're not sure what some of that means, Wiklet is probably tricky for you to install (sorry!), and you should seek help (e.g. learn about web servers and CGI scripts, or ask the person who runs your web server for help).

To install Wiklet:

1. Unpack the [distribution archive](Getting Wiklet).
2. In the directory, run `./install CGI-BIN DOCUMENT-ROOT`, where `CGI-BIN` is the path to the web server’s CGI bin directory, `DOCUMENT-ROOT` is where the wiki files will be stored.
3. Ensure that the directory `DOCUMENT-ROOT/text` and its contents is owned by the user as which the web server runs, and that the contents is readable and writable by that user.
3. Configure the `wiklet.pl` script as described in [Wiklet Configuration].
4. The Wiki should now be ready to use. See [Wiklet Customization] for details of the various ways in which [Wiklet] can be customized.

See [Wiklet Organization] for more details of the layout of the files and URLs used by Wiklet.
