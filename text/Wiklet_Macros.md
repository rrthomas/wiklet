# Wiklet Macros

Macros are special markup which allow things that are not otherwise possible. A macro call is written `\$macro` if the macro takes no arguments, or `\$macro\{arg1,...,argN\}` if it does. Commas in macro arguments must be escaped with backslashes. Unwanted arguments may be omitted.

There are two sorts of macro: those built in to [Wiklet], which are documented below, and those provided by a particular [Wiki], which should be documented in [Local Macros]. Extra [macros](Wiklet Macros) can be added in `wiki.pl`; the default `wiki.pl` gives an example.

Macros are evaluated after Wiki markup, which means that they do not work in certain places, for example as part of a link. Some macros invoke certain [Wiklet Templates].

=`\$scripturl`=
    The URL of the Wiki script.
=`\$homepage`=
    The name of the Wiki's $link{$browse{$homepage},home page}, suitable for displaying as text.
=`\$page`=
    The current page, escaped suitably for use in a URL.
=`\$pagename`=
    The name of the current page, suitable for displaying as text.
=`\$lastmodified`=
    The date on which the current page was last modified.
=`\$url{PATH}`=
    Make a URL from a site-relative path.
=`\$browse{PAGE}`=
    The URL required to browse the given page.
=`\$include{FILE}`=
    Inserts the contents of the given HTML or text file from the templates directory. If the file does not exist, an `abort.htm` error message is shown with \$text set from `nofile.md`.
=`\$link{URL,DESCRIPTION}`=
    Produces a link to the given URL whose displayed text is `DESCRIPTION`.
=`\$filesize{FILE}`=
    Inserts the size of the given file in the download directory.
=`\$image{IMAGE,WIDTH,HEIGHT}`=
    Inserts the given image, which may be either a local file in the `image` directory or a URL. The width and height are in pixels, or a percentage of the available space.
=`\$webfile{FILE,FORMAT}`=
    Produces a link to the given file in the download directory whose text is `FORMAT`, followed by the size of the file.
=`\$counter{PAGE}`=
    Adds a counter, whose value is stored as the contents of page `PAGE`. Every time a page containing the macro call is viewed, the counter is incremented by one. `\$counter` is intended for creating page hit counters, but can also be used to count visits to groups of pages or to a whole site.
=`\$recentchanges`=
    Lists recent changes to the wiki, where "recent" is defined by the `\$Recent` [configuration variable](Wiklet Configuration).
=`\$action`=
    The current action being performed.
=`\$template`=
    The current template being loaded. Useful for constructing the error message in the `nofile.md` [template](Wiki Templates).
=`\$text`=
    The body of the page, set for use by certain [templates](Wiklet Templates).
