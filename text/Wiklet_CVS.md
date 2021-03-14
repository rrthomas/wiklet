# Wiklet CVS

[CVS](https://www.nongnu.org/cvs) is a complex and powerful system, and much of its functionality is not used by Wiklet. The tips below are simple and brief, and you should refer to the [CVS manual](https://www.gnu.org/software/trans-coord/manual/cvs/) for more details.

=_Automatic notification of page edits_=
   CVS can notify you whenever a change is made to a file. To set up email notification, you need to edit the CVSROOT/loginfo file to contain a suitable command (on most Unix-like systems, the line `DEFAULT mail -s "Wiki change: %s" <me\@example.org>` should work).
=_Direct editing_=
   You can edit the wiki pages as plain text files directly using CVS. Using an editor such as [GNU Emacs](https://www.gnu.org/software/emacs) that has support for CVS (and remote file editing, in case you are not running the editor on the web server) makes this particularly convenient. As well as letting you use your favourite editor to edit wiki pages, this is useful if you have [locked pages](Wiklet Security).
