{ nixpkgs ? import <nixpkgs> {} }:

with nixpkgs;
with (import ./. {});

let
  projects = [
    {
      name = "ASRP Classifier";
      url = "https://github.com/dylan-thinnes/asrp-classifier";
      precedence = 6;
      description = ''
        An image classifier to detect landing faces of irregular dice (archimedean
        semi-regular polyhedra) and calculate face probabilities using those samples.
      '';
    }
    {
      name = "Come-N-Go";
      url = "https://come-n-go.com";
      precedence = 7;
      description = ''
        A simple website to help shopkeepers tally visitors to their stores in the interest of social distancing. Built on websockets.
      '';
    }
    {
      name = "conway-wechsler";
      url = "https://github.com/dylan-thinnes/conway-wechsler";
      precedence = 8;
      description = ''
        I'm sure you're familiar with million & billion. Did you know that there is a
        system for writing all the -illions to infinity? conway-wechsler does this all
        for you, so you need never write out a number by hand ever again!
      '';
    }
    {
      name = "cwd";
      url = "https://github.com/dylan-thinnes/cwd";
      precedence = 3;
      description = ''
        Syncs working directories across multiple terminals and lets you push new
        working directories to a stack and pull them quickly. Good for those who live
        in the terminal like me.
      '';
    }
    {
      name = "Domainatrix";
      url = "https://domainatrix.me";
      deprecated = true;
      precedence = 10;
      description = ''
        Cataloguing the nightmare that is the University of Edinburgh's DNS, one step at a time. 
        Peruse the catalogue, Make your own submissions, and see the ping and http statuses of different domains' resolved addresses.
      '';
    }
    {
      name = "fib-nk";
      url = "https://github.com/dylan-thinnes/fib-nk";
      precedence = 4;
      description = ''
        A toy mathematical problem around more generalizations of Fibonacci sequences
        with sample solutions in languages such as Haskell, Haskell's type system, C,
        dc, jq, and Tcl!
      '';
    }
    {
      name = "Haskulate";
      url = "https://github.com/dylan-thinnes/haskulator";
      precedence = 2;
      description = ''
        A one-day shell scripting project to make very quick, in-terminal calculations using the full potential of the Haskell standard library.
        Uses cat and the Glasgow Haskell Compiler.
      '';
    }
    {
      name = "Jobber - A Job Tracker";
      url = "https://github.com/andmikey/jobber";
      precedence = 2;
      description = ''
        Helps you keep track of multiple jobs while on a job hunt. 
        Originally made for a hackathon. 
        Uses React for the UI, Ruby on Rails for the backend. Still a work in progress.
      '';
    }
    {
      name = "me-four";
      url = "https://github.com/dylan-thinnes/me-four";
      precedence = 5;
      description = ''
        A site that can double as a project listing, a contact page, and a blog.
        Built with Bash, nice and lightweight, and completely no-JS compatible.
      '';
    }
    {
      name = "Random Bignum";
      url = "https://github.com/dylan-thinnes/random-bignum-rust";
      precedence = 3;
      description = ''
        Provides large pseudorandom numbers on the command line. Mostly a utility for
        testing conway-wechsler and an attempt at a little program in Rust.
      '';
    }
    {
      name = "SlightlyBetterLectures";
      url = "https://lectures.dylant.org/";
      deprecated = true;
      precedence = 5;
      description = ''
        A lecture hosting site for fellow University of Edinburgh students.
      '';
    }
    {
      name = "SolSys - A Math-Oriented Puzzle";
      url = "http://solsys.xyz";
      precedence = 9;
      description = ''
        A three year art project for the more mathematically reclined.
        Uses AWS Lambda, AWS Gateway, NodeJS, and C++
      '';
    }
    {
      name = "SVGtoJS";
      url = "https://svgtojs.github.io";
      precedence = 1;
      description = ''
        Converts SVG files into a series of drawing commands to a canvas.
        Saves a good deal of space when you need svgs on bitmaps and want to able to modify their attributes quickly, such as stroke and fill color.
      '';
    }
    {
      name = "Word of the Lord - Bringing Stallman to You";
      url = "https://github.com/andmikey/created/blob/master/app.py";
      precedence = 1;
      description = ''
        A completely free and open source hardware/software hack.
        At the press of a button, reads you a random Richard Stallman quote.
        Won the Github 'Spirit of the Hack' award. Run on a Raspberry Pi, using Wikiquotes and espeak.
      '';
    }
    {
      name = "youtube-archive";
      url = "https://github.com/dylan-thinnes/youtube-archive";
      precedence = 1;
      description = ''
        Wraps youtube-dl in helper functions which facilitate multiple simulatneous downloads and remember which videos you've already downloaded.
        This improves on youtube-dl's name-collision approach to download decisions.
      '';
    }
  ];

  toFragment = { url, name, description, precedence, deprecated ? false }: ''
    ${if deprecated
      then "<a class='entry disabled deprecated-project'>"
      else "<a class='entry' href='${url}'>"
    }
      <h3 class='text'>${name}</h3>
      ${description}
    </a>
  '';
in
mkPage {
  title = "(Some) Projects I've Done";
  url = "/projects";
  rawContent = ''
    <h2>Projects I've Done</h2>
    ${builtins.concatStringsSep "\n"
      (builtins.map toFragment projects)}
  '';
}
