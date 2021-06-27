{ nixpkgs ? import <nixpkgs> {} }:

with nixpkgs;
with (import ./pages { inherit nixpkgs; });

let
  sanitizeName = (import ./utils.nix { inherit nixpkgs; }).sanitizeName;
  mkBlogPost =
    { title
    , author ? "Dylan Thinnes"
    , time ? builtins.currentTime
    , description ? ""
    , content
    }:
    let
      date = time; # TODO: actually calculate visible instance of date
      cleanName = sanitizeName title;
      htmlFile =
        runCommand "blog-post-${cleanName}.html"
          {
            buildInputs = [ nixpkgs.pandoc ];
            src = builtins.toFile cleanName ''
              # ${title}

              By ${author}, *Last Edited ${date}*

              ${content}
              '';
          }
          ''
            stat --format="%Y" $src
            pandoc $src -o $out
          '';
      url = "/blog/${cleanName}";
      rawContent = builtins.readFile htmlFile;
    in
    mkPage {
      inherit title url rawContent;
      entry = ''
        <div>
            <a href='${url}' class='entry'>
                <h3 class='text'>${title}</h3>
                <small>By ${author}, <i>Last edited ${date}</i><br></small>
                ${description}
            </a>
        </div>
        '';
    };
in
{
  inherit mkBlogPost;
  outputs = {
    register-machines-in-haskell-recursion-schemes = mkBlogPost (import ./blog-posts-srcs/register-machines-in-haskell-recursion-schemes.nix);
    register-machines-in-haskell-custom-instructions = mkBlogPost (import ./blog-posts-srcs/register-machines-in-haskell-custom-instructions.nix);
    register-machines-in-haskell-labels = mkBlogPost (import ./blog-posts-srcs/register-machines-in-haskell-labels.nix);
    register-machines-in-haskell = mkBlogPost (import ./blog-posts-srcs/register-machines-in-haskell.nix);
    replicator = mkBlogPost (import ./blog-posts-srcs/replicator.nix);
    bash-static-site-generator = mkBlogPost (import ./blog-posts-srcs/bash-static-site-generator.nix);
    guidelines-for-learning-from-projects = mkBlogPost (import ./blog-posts-srcs/guidelines-for-learning-from-projects.nix);
    dc-loops = mkBlogPost (import ./blog-posts-srcs/dc-loops.nix);
    fibnk = mkBlogPost (import ./blog-posts-srcs/fibnk.nix);
    welcome = mkBlogPost (import ./blog-posts-srcs/welcome.nix);
  };
}
