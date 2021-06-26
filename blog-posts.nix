{ nixpkgs ? import <nixpkgs> {} }:

with nixpkgs;
with (import ./pages { inherit nixpkgs; });

let
  mkBlogPost =
    { title
    , author ? "Dylan Thinnes"
    , time ? builtins.currentTime
    , description ? ""
    , content
    }:
    let
      date = time; # TODO: actually calculate visible instance of date
      cleanName = nixpkgs.lib.strings.sanitizeDerivationName title;
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
    replicator = mkBlogPost (import ./nixified-articles/replicator.nix);
  };
}
