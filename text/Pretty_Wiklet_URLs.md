# Pretty Wiklet URLs

If possible, it's nice to set up your web server so that using the URL of the Wiki plus the name of the page causes the page to be shown, i.e. URLs of the form `BaseUrl`/_Foo_ are mapped to the incantation required to view Wiki page _Foo_. This makes URLs pointing into the Wiki much more readable (and easily notable). Once you've set up URL rewriting, you need to set `PrettyURLs` to `1` in `wiklet.pl` (see [Wiklet Configuration]).

Please add instructions for other web servers if you can.

## Apache

Put the following in the `.htaccess` file of the directory specified by `DocumentRoot` in the Wiki configuration, filling in the value of `ScriptUrl` where indicated. For rewrites to work the directory in question has to be in the scope of an `AllowOverride FileInfo` directive. See the [Apache documentation](https://httpd.apache.org/) for the gory details.

```
# wiki remap
#
# This lets us access the wiki with a shorter URI, and also insulates
# it from implementation details (name of script &c.)

RewriteEngine on
RewriteRule ^([^/]*)$ <ScriptUrl>?page=$1
```
