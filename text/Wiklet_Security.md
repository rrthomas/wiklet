# Wiklet Security

First, a disclaimer: serious security is beyond the scope of this manual. Indeed, if you're after heavy-duty authentication and security, you shouldn't be using Wiklet: it is not designed to make content hard to see or change, though it does try hard not to offer any security holes through which the host computer can be attacked.

=_Making pages read-only_=
    Although wikis encourage editing, administrators may find it useful to be able to lock certain pages, for example the front page of a site, or a page of personal information such as a CV, where bad editing might cause annoyance or embarrassment. A page can be locked against writing by making the corresponding file in the @text@ directory not writable by the web server.
=_Password-protected editing_=
    It may be preferable to require a password for all edit operations (perhaps also locking certain pages as an additional level of protection). To do this, place the @edit.htm@ template in a sub-directory of the @template@ directory which is itself protected by HTTP authentication. The details of how to do this depend on the web server; instructions for Apache can be found [in its manual](https://httpd.apache.org/docs/howto/mod_auth_basic.html).