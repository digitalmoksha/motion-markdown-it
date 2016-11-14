4.4.0
-------

Synced with markdown-it 4.4.0, includes these changes:


* 4.4.0 / 2015-07-18
  - Updated HTML blocks logic to CM 0.21 spec.
  - Minor fixes.


* 4.3.1 / 2015-07-15
  - Allow numbered lists starting from zero.
  - Fix class name injection in fence renderer.


* 4.3.0 / 2015-06-29
  - `linkify-it` dependency update (1.2.0). Now accepts dash at the end of links.

* 4.2.2 / 2015-06-10
  - CM spec 0.20.
  - Added support for multichar substituition in smartquites, #115.
  - Fixed code block render inside blockquites, #116.
  - Doc fixes.

* 4.2.1 / 2015-05-01
  - Minor emphasis update to match CM spec 0.19.

* 4.2.0 / 2015-04-21
  - Bumped [linkify-it](https://github.com/markdown-it/linkify-it) version to
  1.1.0. Now links with IP hosts and without protocols are not linkified by
  default, due possible collisions with some version numbers patterns (0.5.0.0).
  You still can return back old behaviour by `md.linkify.set({ fuzzyIP: true })`.

* 4.1.2 / 2015-04-19
  - Bumped linkifier version. More strict 2-chars tald support for links without
  schema. Should not linkify things like `io.js` and `node.js`.

* 4.1.1 / 2015-04-15
  - Improved pipe chars support in table cells, #86 (thanks to @jbt).
