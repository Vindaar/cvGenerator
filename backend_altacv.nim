import std / [strformat, strutils]
import orgparser
import latexdsl_nochecks

import ./cv_types

################################################################################
########################    General & setup    #################################
################################################################################

proc setup(cfg: Config): string =
  ## XXX: make colors, font etc adjustable!
  result = latex:
    ## Use the "normalphoto" option if you want a normal photo instead of cropped to a circle
    # \documentclass[10pt,a4paper,normalphoto]{altacv}

    \documentclass["10pt,a4paper,ragged2e,withhyper"]{altacv}
    ## AltaCV uses the fontawesome5 and simpleicons packages.
    ## See http://texdoc.net/pkg/fontawesome5 and http://texdoc.net/pkg/simpleicons for full list of symbols.

    # Change the page layout if you need to
    \geometry{"left=1.25cm,right=1.25cm,top=1.5cm,bottom=1.5cm,columnsep=1.2cm"}

    # The paracol package lets you typeset columns of text in parallel
    \usepackage{paracol}


    # Change the font if you want to, depending on whether
    # you're using pdflatex or xelatex/lualatex
    # WHEN COMPILING WITH XELATEX PLEASE USE
    # xelatex -shell-escape -output-driver="xdvipdfmx -z 0" mmayer.tex
    \ifxetexorluatex
      # If using xelatex or lualatex:
    \setmainfont{STIXTwoText}
    r"\else"
    # If using pdflatex:
    \usepackage[default]{lato}
    \fi

    # Change the colours if you want to
    \definecolor{VividPurple}{HTML}{"3E0097"}
    \definecolor{SlateGrey}{HTML}{"2E2E2E"}
    \definecolor{LightGrey}{HTML}{"666666"}
    # \colorlet{name}{black}
    \colorlet{tagline}{VividPurple}
    \colorlet{heading}{VividPurple}
    \colorlet{headingrule}{VividPurple}
    # \colorlet{subheading}{PastelRed}
    \colorlet{accent}{VividPurple}
    \colorlet{emphasis}{SlateGrey}
    \colorlet{body}{LightGrey}

    # Change some fonts, if necessary
    # \renewcommand{\namefont}{\Huge\rmfamily\bfseries}
    # \renewcommand{\personalinfofont}{\footnotesize}
    # \renewcommand{\cvsectionfont}{\LARGE\rmfamily\bfseries}
    # \renewcommand{\cvsubsectionfont}{\large\bfseries}

    # Change the bullets for itemize and rating marker
    # for \cvskill if you want to
    \renewcommand{\cvItemMarker}{{\small\textbullet}}
    \renewcommand{\cvRatingMarker}{\faCircle}
    # ...and the markers for the date/location for \cvevent
    # \renewcommand{\cvDateMarker}{\faCalendar*[regular]}
    # \renewcommand{\cvLocationMarker}{\faMapMarker*}


    # If your CV/résumé is in a language other than English,
    # then you probably want to change these so that when you
    # copy-paste from the PDF or run pdftotext, the location
    # and date marker icons for \cvevent will paste as correct
    # translations. For example Spanish:
    # \renewcommand{\locationname}{Ubicación}
    # \renewcommand{\datename}{Fecha}


    ## Use (and optionally edit if necessary) this .tex if you
    ## want to use an author-year reference style like APA(6)
    ## for your publication list
    # \input{pubs-authoryear.cfg}

    ## Use (and optionally edit if necessary) this .tex if you
    ## want an originally numerical reference style like IEEE
    ## for your publication list
    \input{"pubs-num.cfg"}

proc bibliography(file: string): string =
  ## XXX: support!
  ## Bibliography file
  result = latex:
    ## sample.bib contains your publications
    \addbibresource{`file`}

proc personal(cv: CV): string =
  ## XXX: Make it so that only fields with content are added
  ## Add more
  let pinfo = latex:
    # Not all of these are required!
    # You can add your own with \printinfo{symbol}{detail}
    \email{`cv.personal.email`}
    \phone{`cv.personal.phone`}
    # \mailaddress{"Address, Street, 00000 County"}
    # \mailaddress{`cv.personal.home`}
    \location{`cv.personal.location`}
    # \homepage{"marissamayr.tumblr.com"}
    # \twitter{@marissamayer}
    #\xtwitter{"@marissamayer"}
    #\linkedin{marissamayer}
    \github{`cv.personal.github`}
    \printinfo{\faDiscord}{`cv.personal.discord`}
    \printinfo{r"\textbf{Matrix:} "}{`cv.personal.matrix`}
    \printinfo{r"\textbf{Date of birth:} "}{`cv.personal.dateOfBirth`}
    \printinfo{r"\textbf{Nationality:} "}{`cv.personal.nationality`}
    #\matrix{`cv.personal.discord`}
    #\orcid{0000-0000-0000-0000} # Obviously making this up too.
    ## You can add your own arbitrary detail with
    ## \printinfo{symbol}{detail}[optional hyperlink prefix]
    # \printinfo{\faPaw}{Hey ho!}
    ## Or you can declare your own field with
    ## \NewInfoFiled{fieldname}{symbol}[optional hyperlink prefix] and use it:
    # \NewInfoField{gitlab}{\faGitlab}[https://gitlab.com/]
    # \gitlab{your_id}
    ##
    ## For services and platforms like Mastodon where there isn't a
    ## straightforward relation between the user ID/nickname and the hyperlink,
    ## you can use \printinfo directly e.g.
    # \printinfo{\faMastodon}{@username@instace}[https://instance.url/@username]
    ## But if you absolutely want to create new dedicated info fields for
    ## such platforms, then use \NewInfoField* with a star:
    # \NewInfoField*{mastodon}{\faMastodon}
    ## then you can use \mastodon, with TWO arguments where the 2nd argument is
    ## the full hyperlink.
    # \mastodon{@username@instance}{https://instance.url/@username}

  result = latex:
    \name{`cv.personal.name`}
    \tagline{`cv.personal.tagline`}
    # Cropped to square from https://en.wikipedia.org/wiki/Marissa_Mayer#/media/File:Marissa_Mayer_May_2014_(cropped).jpg, CC-BY 2.0
    ## You can add multiple photos on the left or right
    \photoR{"2.5cm"}{`cv.personal.photo`}
    # \photoL{2cm}{Yacht_High,Suitcase_High}
    \personalinfo{`pinfo`}

proc documentSetup(): string =
  ## XXX: Make column ratio adjustable
  result = latex:
    \makecvheader

    ## Depending on your tastes, you may want to make fonts of itemize environments slightly smaller
    \AtBeginEnvironment{itemize}{\small}

    ## Set the left/right column width ratio to 6:4.
    \columnratio{0.6}


################################################################################
#######################    Left hand column    #################################
################################################################################

proc getDates[T](pList: T, includeDates: bool = true): string =
  if not includeDates: return
  let frm = pList.`from`
  let to = pList.to

  if frm.len > 0 and to.len > 0:
    result = &"{frm} -- {to}"
  elif frm.len > 0:
    result = frm
  elif to.len > 0:
    result = to
  # else empty

proc getCompanyOrUni[T](pList: T): string =
  ## Returns the company, employer or university
  let opts = [pList.uni, pList.employer, pList.company, pList.organization]
  for x in opts:
    if x.len > 0:
      return x

proc getDescription[T: SomeEntry](el: T): string =
  let itemizeSec = el.description.escapeLatex.itemizeData.toItemize()
  if itemizeSec.len > 0:
    result = itemizeSec
  else:
    result = el.description.escapeLatex

proc work(cv: CV): string =

  result = latex:
    \cvsection{Experience}

  for el in cv.work:
    # XXX: determine what type of employemnt and decide the "uni" "corporation" etc field
    let fromTo = el.pList.getDates()
    # XXX: determine which location to use
    var loc: string
    if el.pList.city.len > 0 and el.pList.country.len > 0:
      loc = &"{el.pList.city}, {el.pList.country}"
    elif el.pList.city.len > 0:
      loc = &"{el.pList.city}"
    elif el.pList.country.len > 0:
      loc = &"{el.pList.country}"

    let desc = getDescription(el)
    let company = el.pList.getCompanyOrUni()

    let event = latex:
      \cvevent{`el.title.escapeLatex`}{`company`}{`fromTo`}{`loc`}
      `desc`
      \divider
    result.add event
  if cv.cfg.wKey in cv.cfg.newPageAfter:
    result.add latex do:
      \newpage

proc dayInLife(): string =
  let wheel = latex:
    r"10/13em/accent!30/Sleeping \& dreaming about work,"
    r"25/9em/accent!60/Public resolving issues with Yahoo!\ investors,"
    r"5/11em/accent!10/\footnotesize\\[1ex]New York \& San Francisco Ballet Jawbone board member,"
    r"20/11em/accent!40/Spending time with family,"
    r"5/8em/accent!20/\footnotesize Business development for Yahoo!\ after the Verizon acquisition,"
    r"30/9em/accent/Showing Yahoo!\ \mbox{employees} that their work has meaning,"
    r"5/8em/accent!20/Baking cupcakes"

  result = latex:
    \cvsection{A Day of My Life}

    # Adapted from @Jake's answer from http://tex.stackexchange.com/a/82729/226
    # \wheelchart{outer radius}{inner radius}{
    # comma-separated list of value/text width/color/detail}
    # Some ad-hoc tweaking to adjust the labels so that they don't overlap
    \hspace*{"-1em"}  ## quick hack to move the wheelchart a bit left
    \wheelchart{"1.5cm"}{"0.5cm"}{`wheel`}
    ## XXX: newpage?
    # use ONLY \newpage if you want to force a page break for
    # ONLY the currentc column
    \newpage

proc publications(): string =
  let names = latex:
    r"Lim/Lian\bibnamedelima Tze,"
    r"Wong/Lian\bibnamedelima Tze,"
    r"Lim/Tracy,"
    r"Lim/L.\bibnamedelimi T."
  result = latex:
    \cvsection{Publications}

    ## Specify your last name(s) and first name(s) as given in the .bib to automatically bold your own name in the publications list.
    ## One caveat: You need to write \bibnamedelima where there's a space in your name for this to work properly; or write \bibnamedelimi if you use initials in the .bib
    ## You can specify multiple names, especially if you have changed your name or if you need to highlight multiple authors.
    \mynames{`names`}
    ## MAKE SURE THERE IS NO SPACE AFTER THE FINAL NAME IN YOUR \mynames LIST

    \nocite{"*"}

    \printbibliography[r"heading=pubtype,title={\printinfo{\faBook}{Books}},type=book"]

    \divider

    \printbibliography[r"heading=pubtype,title={\printinfo{\faFile*[regular]}{Journal Articles}}, type=article"]

    \divider

    \printbibliography[r"heading=pubtype,title={\printinfo{\faUsers}{Conference Proceedings}},type=inproceedings"]

proc projects(cv: CV): string =
  result = latex:
    \cvsection{Selected projects}

  for el in cv.projects:
    # XXX: determine what type of employemnt and decide the "uni" "corporation" etc field
    let fromTo = el.pList.getDates(cv.cfg.projIncludeDates)
    let desc = el.getDescription()
    let event = latex:
      \cvevent{\href{`el.pList.links`}{`el.title.escapeLatex`}}{`fromTo`}{}{}
      `desc`
      \divider
    result.add event
    #result.add "\n" & r"\newpage"



################################################################################
#######################    Right hand column     ###############################
################################################################################

proc lifePhilosophy(): string =
  result = latex:
    \cvsection{Life Philosophy}
    quote:
      r"``If you don't have any shadows, you're not standing in the light.''"

proc mostProudOf(): string =
  result = latex:
    \cvsection{"Most Proud of"}

    \cvachievement{\faTrophy}{Courage I had}{"to take a sinking ship and try to make it float"}

    \divider

    \cvachievement{\faHeartbeat}{r"Persistence \& Loyalty"}{"I showed despite the hard moments and my willingness to stay with Yahoo after the acquisition"}

    \divider

    \cvachievement{\faChartLine}{r"Google's Growth"}{"from a hundred thousand searches per day to over a billion"}

    \divider

    \cvachievement{\faFemale}{"Inspiring women in tech"}{"Youngest CEO on Fortune's list of 50 most powerful women"}

proc strengths(): string =
  result = latex:
    \cvsection{Strengths}

    \cvtag{"Hard-working (18/24)"}
    \cvtag{Persuasive}"\\"
    \cvtag{r"Motivator \& Leader"}

    \divider\smallskip

    \cvtag{UX}
    \cvtag{r"Mobile Devices \& Applications"}
    \cvtag{r"Product Management \& Marketing"}

proc skills(cv: CV): string =
  result = latex:
    \cvsection{Skills}

  var skills: string
  for sec in cv.skills:
    ## XXX: add `\divider` after each skill section?
    for x in sec.skills:
      let skill = latex:
        \cvtag{`x`}
      skills.add skill
    skills.add "\n"
    skills.add latex do:
      \divider\smallskip
    skills.add "\n"
  result.add skills


proc languages(cv: CV): string =
  ## XXX: Improve the language mapping
  result = latex:
    \cvsection{Languages}

  # first the mother tongue
  let mt = latex:
    \cvskill{`cv.langs.motherTongue`}{5}
  result.add mt
  # now all foreign
  for l in cv.langs.foreign:
    let lvl = case l.pList.combinedLevel
              of "A1": 0.5
              of "A2": 1.5
              of "B1": 2
              of "B2": 3
              of "C1": 4
              of "C2": 5
              else: raiseAssert "Invalid language level: " & $l.pList.combinedLevel
    let fl = latex:
      \cvskill{`l.title`}{`lvl`}
    result.add fl

proc education(cv: CV): string =
  result = latex:
    \cvsection{Education}

  for el in cv.education:
    let fromTo = el.pList.getDates()
    var thesis, grade: string
    if el.pList.thesis.len > 0:
      thesis = r"\textbf{Thesis:} " & el.pList.thesis & r"\\"
    if el.pList.finalGrade.len > 0:
      grade = r"\textbf{Final grade:} " & el.pList.finalGrade & r"\\"

    let desc = el.getDescription()
    let event = latex:
      \cvevent{`el.title.escapeLatex`}{`el.pList.uni`}{`fromTo`}{}
      `thesis`
      `grade`
      `desc`
      \divider
    result.add event

proc referees(): string =
  result = latex:
    \cvsection{Referees}

    # \cvref{name}{email}{mailing address}
    \cvref{r"Prof.\ Alpha Beta"}{Institute}{"a.beta@university.edu"}
    {Address Line 1\\Address line 2}

    \divider

    \cvref{r"Prof.\ Gamma Delta"}{Institute}{"g.delta@university.edu"}
    {Address Line 1\\Address line 2}

proc switchColumn(): string =
  ## Switch the column from left to right
  result = latex:
    ## Switch to the right column. This will now automatically move to the second
    ## page if the content is too long.
    \switchcolumn

proc genCv*(cv: CV): string =
  ## Generate the actual CV by filling the LaTeX template for AltaCV.
  var setup: string
  setup.add cv.cfg.setup()
  setup.add bibliography("sample.bib")

  var header: string
  header.add cv.personal()
  header.add documentSetup()

  template addIt(s, d): untyped =
    s.add d & "\n"

  var doc: string
  # 1. Left hand side
  if cfWork in cv.fieldsAdded:
    doc.addIt cv.work()
  #doc.add dayInLife() & "\n"
  #doc.add publications() & "\n"

  # 2. Switch the columns
  doc.addIt switchColumn()

  # 3. Right hand side
  if cfEducation in cv.fieldsAdded:
    doc.addIt cv.education()
  if cfLangs in cv.fieldsAdded:
    doc.addIt cv.languages()
  if cfSkills in cv.fieldsAdded:
    doc.addIt cv.skills()
  if cfProjects in cv.fieldsAdded:
    doc.addIt cv.projects()

  #doc.add lifePhilosophy() & "\n"
  #doc.add mostProudOf() & "\n"
  #doc.add strengths() & "\n"
  #doc.add referees() & "\n"

  # 4. Finalize
  result = latex:
    `setup`
    document:
      # Start a 2-column paracol. Both the left and right columns will automatically
      # break across pages if things get too long.
      `header`
      paracol{2}:
        `doc`

when isMainModule:
  let cv = cv.genCv()

  compile("/tmp/test_cv.tex", cv, fullBody = true)
