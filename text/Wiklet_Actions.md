# Wiklet Actions

[Wiklet] is called by passing arguments to `wiklet.pl` (typically in the URL). The most important arguments are `action`, which defaults to `view`, and `page`, which defaults to `HomePage` as given in the [Wiklet Configuration]. The supported actions are listed below. Some actions take other arguments, which are listed with the corresponding action.

=`view`=
    Returns a page for viewing, rendering it first if the cache is not up to date.
=`edit`=
    Edit the given `page`.
=`save`=
    Save the given `page` under the name `pagename`. If `pagename` is empty, the page is deleted. `text` gives the new text. The browser is then redirected to view the page (if it no longer exists, it goes back to the home page).
