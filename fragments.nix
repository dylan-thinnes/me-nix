{ nixpkgs ? import <nixpkgs> {} }:

with nixpkgs;

let static = import ./static.nix { inherit nixpkgs; };
in
{
  favicon = ''
    <!--<link 
        rel='apple-touch-icon' 
        sizes='180x180' 
        href='${static.outputs.faviconDir.blogPath}/apple-touch-icon.png'
        >-->
    <link 
        rel='icon' 
        type='image/png' 
        sizes='32x32' 
        href='${static.outputs.faviconDir.blogPath}/favicon-32x32.png'
        >
    <link 
        rel='icon' 
        type='image/png' 
        sizes='16x16' 
        href='${static.outputs.faviconDir.blogPath}/favicon-16x16.png'
        >
    <link 
        rel='mask-icon' 
        href='${static.outputs.faviconDir.blogPath}/safari-pinned-tab.svg' 
        color='#2b5797'
        >
    <link 
        rel='shortcut icon' 
        href='${static.outputs.faviconDir.blogPath}/favicon.ico'
        >
    <meta name='theme-color' content='#ffffff'>
    '';

  section-colorize = url:
    let
      selector =
        if url == ""
        then ".section[data-url] > .section-container"
        else ".section[data-url=\"${url}\"] > .section-container";
      colors = {
        "/projects" = "#44af69";
        "/blog" = "#f8333c";
        "/contact" = "#2b9eb3";
        "/about" = "#ff6600";
        "/links" = "#732d9c";
      };
      color = colors.${url} or "#333333";
    in
    ''
      <style>
      ${selector} {
          border-color: ${color};
      }
      ${selector} .text {
          color: ${color};
      }
      ${selector} h1, ${selector} h2, ${selector} h3, ${selector} h4, ${selector} h5, ${selector} h6 {
          color: ${color};
      }
      ${selector} h1, ${selector} h2 {
          border-bottom: 2px solid ${color};
          padding-bottom: 4pt;
      }
      </style>
    '';

  profile = url:
    let profileImgStyle =
          if url == "/" then
            "style='background-image: url(${static.outputs.profileImage.blogPath})'"
          else
            "";
    in ''
      <div id='profile' ${profileImgStyle}></div>
      <style>
      /* profile picture */
      #profile {
          border-radius: 1em;
          background-size: 25ch;
          background-position: center;
          background-repeat: no-repeat;
          width: 25ch;
          height: 25ch;
          align-self: center;
          transition: height 0.5s ease-out 0s;
      }
      </style>
    '';
}
