# Wiklet Templates

The layout of the [Wiklet] pages can be customized by editing the files in @template@. There is one file for each Wiklet action and some general-purpose files. These are as follows:

=`view.htm`=
    Page view template. The page contents is in the `\$text` [macro](Wiklet Macros).
=`edit.htm`=
    Page editing template. The page contents is substituted for the magic macro `\$TEXT`, which is expanded after the other macros, so that its contents is not subject to macro expansion.
=`abort.htm`=
    This template is used for error messages. The [macro](Wiklet Macros) `\$text` contains the error message.
=`nav.htm`=
    Contains the navigation bar.
=`menu.htm`=
    Contains the menu of links that goes in the navigation bar.
=`readonly.md`=
    The error message displayed when a page cannot be edited.
=`noaction.md`=
    The error message displayed when a non-existent Wiki action is attempted.
=`nofile.md`=
    The error message displayed when a non-existent file is loaded (this is used by the `\$include` [macro](Wiklet Macros)).

Some other templates are used by particular macros, and are documented with the corresponding macro in [Wiklet Macros].
