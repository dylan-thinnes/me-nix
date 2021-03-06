{ nixpkgs ? import <nixpkgs> {} }:

with nixpkgs;
with (import ./. {});

let static = import ../static.nix {};
in
mkPage {
  title = "About Me";
  url = "/about";
  rawContent = ''
<h2>About Me & This Site</h2>
<h3>Who are you?</h3>
<p>
    Hello, my name is Dylan! I'm currently studying Computer Science at the
    University of Edinburgh, welcome to my website.
</p>

<p>
    I'm very passionate about technology's capacity to connect and inform
    people. I love coming up with novel platforms and projects, even more if
    I can apply some newfangled language while I do it.
</p>

<h3>About this Site</h3>
<p>
    I wanted to make a site that prioritizes having a very small footprint,
    yet still looks nice and behaves like a single page site, and can
    gracefully drop back if JavaScript is disabled. I think I succeeded in
    that respect.
    <ul>
        <li>
            Aside from content and profile picture, the server sends less
            than 5 kilobytes over the network after assets are minified and
            compressed.
        </li>
        <li>
            When Javascript is disabled, links to different endpoints
            request prerendered static assets that are identical to what
            would be dynamically loaded if JS were enabled.
        </li>
        <li>
            When Javascript is enabled, it takes over regular link
            behaviour and uses XHR and the History API instead, loading
            only the content you need.
        </li>
    </ul>
    To see the source code, go to 
    <a href='https://github.com/dylan-thinnes/me-four'>Github</a>.  
</p>
To see licensing info for all JavaScript on this site:
<table id='jslicense-labels1'>
    <tr>
        <td><a href='${static.outputs.js.blogPath}'>minified code</a></td>
        <td><a href='http://www.gnu.org/licenses/gpl-3.0.html'>GPL v3 license</a></td>
        <td><a href='${static.outputs.js.blogPath}'>source code</a></td>
    </tr>
</table>
  '';
}
