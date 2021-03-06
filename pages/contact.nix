{ nixpkgs ? import <nixpkgs> {} }:

with nixpkgs;
with (import ./. {});

let static = import ../static.nix {};
in
mkPage {
  title = "Contact Me";
  url = "/contact";
  rawContent = ''
<h2>Contact & CV</h2>

<div><a href='mailto://dylan.thinnes@protonmail.com' class='entry' data-disable-mocking='true'>
  <h3 class='text'>dylan.thinnes@protonmail.com</h3>
  <small>
    This email is for general inquiries and items not directly related to
    programming.
    Reply time will be anywhere from 0.5-7 days depending on urgency, time of
    year, and timezones.
  </small>
</a></div>

<div><a href='https://github.com/dylan-thinnes' class='entry' data-disable-mocking='true'>
  <h3 class='text'>github/dylan-thinnes</h3>
  <small>
    For inquiries/discussion related to programming, especially one of my
    existing projects, I recommend contacting me on GitHub.
  </small>
</a></div>

<div><a href='https://linkedin.com/in/dylan-thinnes' class='entry' data-disable-mocking='true'>
  <h3 class='text'>linkedin.com/in/dylan-thinnes</h3>
  <small>
    For inquiries/discussion related to business or employment, I recommend
    contacting me on LinkedIn.
  </small>
</a></div>

<div><a href='${static.outputs.cvpdf.blogPath}' class='entry' data-disable-mocking='true'>
  <h3 class='text'>For my CV, click here.</h3>
</a></div>
  '';
}
