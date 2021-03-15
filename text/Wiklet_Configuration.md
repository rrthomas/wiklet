# Wiklet Configuration

[Wiklet] is configured in the `wiki.pl` script. The configuration variables are as follows:

=`BaseUrl`=
   The base URL of the Wiki relative to the web site. It will typically contain a leading slash. It is used to construct relative URLs to make links within the Wiki. An absolute URL (excluding the initial `https:`) can be used if desired.
=`ScriptUrl`=
   The URL of the Wiki script relative to the web site. The same remarks apply as to `BaseUrl`.
=`PrettyUrls`=
   Leave this line commented out unless you want to use [Pretty Wiklet URLs]. Since this can be fiddly, it's a good idea to wait until you've got Wiklet working before trying to get this set up.
=`HomePage`=
   The name of the home page of the Wiki, which is displayed by default (when no page is specified).
=`DocumentRoot`=
   The directory in which the `text`, `template`, `download` and `image` directories live.
=`Recent`=
   The number of days considered recent for the [Recent Changes] page.

If you want to have more than one wiki, make a copy of `wiki.pl` under a different name for each Wiki and configure each copy appropriately.

You can improve Wiklet's performance by running it persistently. The recommended way to do this is to use [SpeedyCGI](http://www.daemoninc.com/SpeedyCGI/) (also called PersistentPerl). Having installed this, you need to use it to run `wiki.pl`; on many systems this is achieved by changing the first line of `wiki.pl` to use `speedy` instead of `perl`.
