{ nixpkgs ? import <nixpkgs> {} }:

with nixpkgs;
with (import ./. {});

let
  links = [
    {
      url = "https://www.youtube.com/watch?v=lvh6NLqKRfs";
      name = "The Bob Emergency (Part 1)";
      description = ''
        Jon Bois is a sports writer who has a knack for finding great stories, telling
        them beautifully, and backing them up with encyclopedic sports stats knowledge.
        <br/><br/>
        This is part 1 of his two-hour video series about the disappearance and legacy
        of the name "Bob" in sports.
      '';
    }
    {
      url = "http://www.math.ucr.edu/home/baez/crackpot.html";
      name = "Crackpot Index";
      description = ''
        Have you ever read a paper or article on some new marvel of the information age
        that seemed a bit out there? Well with this handy guide, you can now
        definitively rank them!
      '';
    }
    {
      url = "https://archive.nytimes.com/www.nytimes.com/books/first/h/hoffman-man.html";
      name = "The Man Who Loved Only Numbers";
      description = ''
        The first chapter of "The Man Who Loved Only Numbers" gives a unique snapshot
        of Paul Erdös, a wonderful, highly influential, and (above all) adorably quirky
        mathematician.
      '';
    }
    {
      url = "https://archive.org/details/FarewellEtaoinShrdlu";
      name = "Farewell, Etaoin Shrdlu";
      description = ''
        A thought-provoking 30-minute documentary about the last day of the linotype at
        the New York Times, and the transfer to cold type.
        <br/><br/>
        It's an interesting look into the persistent change of technology, and
        ultimately how people adapt to those changes.
      '';
    }
    {
      url = "https://www.youtube.com/watch?v=CPRvc2UMeMI";
      name = "Every OS Sucks - Wes Borg";
      description = ''
        A ballad to the suckiness of every OS. As one verse eloquently puts it,
        "Everything since the abacus is just a bunch of crap."
      '';
    }
    {
      url = "https://en.wikipedia.org/wiki/Wikipedia:Lamest_edit_wars";
      name = "Lamest Edit Wars";
      description = ''
        This page summarizes some of the funniest and longest-running "edit wars" on
        Wikipedia, a situation in which two (or more) people keep editing the same
        pages to disagree with one another recounting of events. I suppose it's a
        record which proves that even in the most hallowed halls of community, there is
        still the obscenely petty and the sourest of grapes. Enjoy!
      '';
    }
    {
      url = "http://orteil.dashnet.org/nested";
      name = "Nested by Orteil";
      description = ''
        Orteil is better known for his idle game, Cookie Clicker, but I'm much more
        fond of his infinite, recursive, super-meta universe exploration game. 
        <br/><br/>
        Who would've thought clicking trees of tabs could be so fun!
      '';
    }
    {
      url = "http://www.decisionproblem.com/paperclips/index2.html";
      name = "Paperclip";
      description = ''
        Based on a thought experiment where an AI, when given the innocuous order to
        create paperclips, proceeds to convert the world (and beyond) to wire to meet
        its goal.

        Play the stock market, develop autonomous swarms, and armor your Von Neumann
        probes to become the undisputed paperclip maker of our universe.
      '';
    }
    {
      url = "https://rifters.com/real/shorts.htm";
      name = "Peter Watts's Shorts & Backlist";
      description = ''
        Peter Watts is the harshest, bleakest scifi author I've ever read. He
        especially loves beating you over the head with your general insignificance on
        a cosmic scale and your eventual obsolescence as we enter the century of
        singularities & killer robots. Good stuff!
        <br/><br/>
        This is a backlist he keeps of some of his works and short stories, free to
        read! I particularly enjoyed "The Island", for which he won the Hugo Award.
      '';
    }
    {
      url = "http://www.orwell.ru/library/essays/politics/english/e_polit";
      name = "Politics & the English Language";
      description = ''
        In this essay, Orwell illuminates his very pragmatic, terse approach to
        political writing & the English language in general. Especially fun reading if
        you do any public speaking or writing of your own and sometimes struggle to get
        your point across.
      '';
    }
    {
      url = "http://homepages.inf.ed.ac.uk/rni/papers/realprg.html";
      name = "Real Programmers Don't Use Pascal";
      description = ''
        A funny, tongue-in-cheek piece on what makes and unmakes the True Programmers
        among us.
      '';
    }
    {
      url = "https://en.wikipedia.org/wiki/Small-world_experiment#Basic_procedure";
      name = "Methodology of \"Six Degrees of Separation\"";
      description = ''
        Many people are familiar with the concept of "six degrees of separation",
        derived from renowned psychologist Stanley Milgram's finding that Americans are
        separated by (on average) 6 social links.<br/><br/>

        The experiment's methodology is amusing enough to link here, it's a very simple
        solution to what seems a complex problem in experimental design. A following
        section on the page, <b>Criticisms</b>, is also a cool read that covers the
        flaws in this delightfully simple solution.
      '';
    }
    {
      url = "https://www.thesr71blackbird.com/Aircraft/Stories/speed-check";
      name = "That SR-71 Speed Check Story";
      description = ''
        The SR-71 Blackbird was a (very) fast US spyplane deployed during the Cold War.
        This is a fun story that lots of people will recognize as "That SR-71 Speed
        Check" story, in which a couple of Blackbird pilots show off their
        multi-million-dollar marvel of engineering to the Whole West Coast.
      '';
    }
    {
      url = "https://www.youtube.com/watch?v=yhuMLpdnOjY";
      name = "We Will All Go Together When We Go - Tom Lehrer";
      description = ''
        Tom Lehrer is a mathematician & musical satirist who was active in the 50s &
        60s. 
        <br/><br/>
        He has so many great songs that it's hard to choose, but I've settled for
        "We Will All Go Together When We Go", an uplifting celebration of nuclear
        holocaust.
      '';
    }
    {
      url = "https://aphyr.com/posts/342-typing-the-technical-interview";
      name = "Typing the Technical Interview";
      description = ''
        A great witch comes to an interview at a mortal company and solves n-queens
        with her type magic. What's especially funny is some type-magicians actually
        are this eccentric.
      '';
    }
    {
      url = "https://dan.hersam.com/lists/date_excuses.html";
      name = "Useful Excuses";
      description = ''
        A list of excuses for getting out of sticky situations. The whole
        site is full of fun pages - I also recommend the "not too bright" and
        "oxymorons" sections, visible in the sidebar.
      '';
    }
    {
      url = "https://www.youtube.com/watch?v=VIVIegSt81k";
      name = "Hexaflexagons - Vi Hart";
      description = ''
        Vi Hart's upbeat and torrential videos always manage to put a smile on my face.
        This is one of my favourites by her, on hexaflexagons, a very soothing kind of
        paper toy and topological curiosity.
      '';
    }
  ];

  toFragment = { url, name, description }: ''
    <div>
        <a href='${url}' data-disable-mocking='true' class='entry'>
          <h3 class='text'>${name}</h3>
          ${description}
        </a>
    </div>
  '';
in
mkPage {
  title = "Links I Find Interesting";
  url = "/links";
  rawContent = ''
    <h2>Links I Find Interesting</h2>
    ${builtins.concatStringsSep "\n"
      (builtins.map toFragment links)}
  '';
}
