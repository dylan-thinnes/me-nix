{ nixpkgs ? import <nixpkgs> {} }:

with nixpkgs;

let
  static = import ../static.nix { inherit nixpkgs; };
  fragments = import ../fragments.nix { inherit nixpkgs; };
  sanitizeName = (import ../utils.nix { inherit nixpkgs; }).sanitizeName;

  mkPage = args@{ title, url, rawContent, ... }:
    let
      surrounded = builtins.toFile "surrounded" (surroundWithPage args);
      nolayout = builtins.toFile "nolayout" ''
        ${fragments.section-colorize url}
        ${rawContent}
        '';
    in
    args // {
      blogPath = url;
      forest = runCommand "forest-${sanitizeName title}" {} ''
        mkdir -p $out/${url}
        cp ${surrounded} $out/${url}/index.html
        mkdir -p $out/nolayout/${url}
        cp ${nolayout} $out/nolayout/${url}/index.html
      '';
    };

  surroundWithPage = { title, url, rawContent, ... }:
    let
      bodyClass = if url == "/" then "" else "open";
      content =
        if url == "/" then ''
          <div class='section selected' data-url='/' style='opacity: 0'></div>
        '' else ''
          <div class='section selected' data-url='${url}'>
              <title>${title}</title>
              <div class='section-container'>
                  ${rawContent}
              </div>
          </div>
        '';
    in ''
      <!DOCTYPE html>
      <html>
          <head>
              <title>${title}</title>
              <meta name='viewport' content='width=device-width, initial-scale=1'>
              <meta charset='utf-8'>
              ${fragments.favicon}
              <link href='${static.outputs.css.blogPath}' rel='stylesheet' />
              ${fragments.section-colorize url}
          </head>

          <body class='${bodyClass}'>
              <div class='spacer'></div>
              ${fragments.profile url}
              <div id='name'><a href='/' class='reset'>Dylan Thinnes</a></div>
              <div id='social'>
                  <a class='contact-bg' href='/contact'>contact</a>
                  <a class='projects-bg' href='/projects'>projects</a>
                  <a class='blog-bg' href='/blog'>blog</a>
                  <a class='about-bg' data-jslicense='1' href='/about'>about</a>
                  <a class='links-bg' href='/links'>links</a>
              </div>
              <div id='blurb'>
                  I am a student of Comp Sci at the University of
                  Edinburgh.<br/>In my spare time, I enjoy camping, Aikido, and
                  coding.
              </div>
              <div id='content'>
                  ${content}
                  <div class='section' id='error'>
                      <div class='text'>An error occurred.</div>
                  </div>
                  <div class='section' id='loading'>
                      <div class='text'>Loading...</div>
                  </div>
              </div>
              <div class='spacer'></div>
              <script src='${static.outputs.js.blogPath}'></script>
          </body>
      </html>
    '';
in
{
  inherit mkPage;
  outputs = {
    root = mkPage { title = "Dylan Joseph Thinnes"; url = "/"; rawContent = ""; };
    about = import ./about.nix { inherit nixpkgs; };
    contact = import ./contact.nix { inherit nixpkgs; };
    blog = import ./blog.nix { inherit nixpkgs; };
    projects = import ./projects.nix { inherit nixpkgs; };
    links = import ./links.nix { inherit nixpkgs; };
  };
}
