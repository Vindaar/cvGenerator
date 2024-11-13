import orgparser

type
  BackendKind* = enum
    bkModernCV, bkAltaCV

  ## Important note about the Config fields:
  ## The field names specific to the objects e.g. `pName`,
  ## (`p` suffix for Personal), *must* match exactly those of the
  ## object they reference (e.g. the `name` field of the `PersonalInfo` object),
  ## because we use a macro to assign them.
  Config* = object
    # Style / layout config
    ## XXX: support in all sections! Currently only after work!
    newPageAfter*: seq[string] # Hand a single element tuple with a section name after which you want a `\newpage`
    # personal information configuration
    pKey* = "personal_info" # CUSTOM_ID in the Org file
    pName* = "Name"
    pEmail* = "Email"
    pHome* = "Home"
    pPhone* = "Phone"
    pGithub* = "GitHub"
    pMatrix* = "Matrix"
    pDiscord* = "Discord"
    pTagline* = "Tagline"
    pDateOfBirth* = "DateOfBirth"
    pNationality* = "Nationality"
    pLocation* = "Location"
    pPhoto* = "Photo"

    # education configuration
    eKey* = "Education"
    eFrom* = "From"
    eTo* = "To"
    eUni* = "Uni"
    eAddress* = "Address"
    eDepartment* = "Department"
    eFinalGrade* = "FinalGrade"
    eThesis* = "Thesis" # title of the thesis
    eLinks* = "Links" # additional links e.g. to the thesis

    # Languages
    lKey* = "Language skills"
    lMotherTongue* = "MotherTongue" # property of `lKey` section
    lCombinedLevel* = "CombinedLevel"
    # Individual language keys

    # Work experience
    wKey* = "Work experience"
    wFrom* = "From"
    wTo* = "To"
    wUni* = "Uni"
    wAddress* = "Address"
    wDepartment* = "Department"
    wLinks* = "Links"
    wOrganization* = "Organization"
    wCompany* = "Company"
    wEmployer* = "Employer"
    wCity* = "City"
    wCountry* = "Country"

    # Publication
    pubKey* = "Publications" ## XXX: Might end up just calling to a .bib file

    # Projects
    projKey* = "Projects"
    projFrom* = "From"
    projTo* = "To"
    projLinks* = "Links"
    projIncludeDates* = true
    projLeft* = true # whether to print projects in left or right column

    # Skills
    skillKey* = "Skills"

    # Bibliography
    bKey* = "Publications"
    bFile* = "Bibliography" # the key in the `Publications` properties containing the file name of the `.bib` file
    bLeft* = true # whether to print publications in left or right column

  CVFields* = enum
    cfPersonal, cfEducation, cfWork, cfPublications, cfProjects, cfSkills, cfLangs

  CV* = object
    # config
    cfg*: Config
    # Data sources
    orgSource*: string
    org*: OrgNode
    # Backend
    backend*: BackendKind
    # Parsed information
    fieldsAdded*: set[CVFields] # which of the below fields are actually desired
    personal*: PersonalInfo
    education*: Education
    work*: Work
    publications*: Publications
    projects*: Projects
    skills*: Skills
    langs*: Languages
    bibliography*: string # The file to use for the bibliography, a `.bib` file

  PersonalInfo* = object
    name*: string
    email*: string
    home*: string
    phone*: string
    github*: string
    matrix*: string
    discord*: string
    tagline*: string
    dateofbirth*: string
    nationality*: string
    location*: string
    photo*: string # path to a picture

  ## Can be a degree, school or whatever
  EducationEntryPList* = object
    `from`*: string
    to*: string
    uni*: string
    address*: string # address of the institution
    department*: string
    finalGrade*: string
    thesis*: string # title of the thesis
    links*: string # additional links e.g. to the thesis

  EducationEntry* = object
    title*: string # the degree (section title)
    pList*: EducationEntryPList
    description*: string # General description about the degree / school / ...

  Education* = seq[EducationEntry] # object
  #  s*: seq[EducationEntry] #
  WorkEntryPList* = object
    `from`*: string
    to*: string
    uni*: string
    address*: string
    department*: string
    links*: string
    organization*: string
    company*: string
    employer*: string
    city*: string
    country*: string

  WorkEntry* = object
    title*: string # title of the entry
    pList*: WorkEntryPList
    description*: string

  LanguagePList* = object
    combinedLevel*: string

  Language* = object
    title*: string # the language (title of section)
    pList*: LanguagePList

  Languages* = object
    motherTongue*: string
    foreign*: seq[Language]

  ProjectPList* = object
    `from`*: string
    to*: string
    links*: string

  Project* = object
    title*: string # Title of the project
    pList*: ProjectPList
    description*: string

  Work* = seq[WorkEntry]
  Publication* = object
  Publications* = seq[Publication]

  Projects* = seq[Project]

  SkillSection* = object
    section*: string # Name of the section (to filter to individual sections for export)
    skills*: seq[string]
  Skills* = seq[SkillSection]

  ## Just a helper for `itemize` environments
  Item* = tuple[item: string, level: int] # int is the level of nesting


proc initCV*(fname: string, backend: BackendKind): CV =
  let org = parseOrg(fname)
  result = CV(orgSource: fname, org: org, backend: backend)


proc escapeLatex*(s: string): string =
  ## NOTE: Adapted `ginger/backendTikz.nim`
  ## For now: We simply do not escape unless the user asks for it via CT or RT
  ## setting.
  ## We also only escape "safe" things. I.e. anything math related we leave as is
  ## and only replace `\n` by `\\` and `%`, `#`, `&` by their `\` prefixed versions.
  result = newStringOfCap(s.len)
  template addIf(res, arg): untyped =
    doAssert arg.len == 2
    if last != '\\':
      res.add arg
    else:
      res.add arg[^1]
  var last = '\0'
  var inMath = false
  for c in s:
    case c
    of '%': result.addIf r"\%"
    of '#': result.addIf r"\#"
    of '&': result.addIf r"\&"
    of '$':
      inMath = not inMath
      result.add c
    of '_':
      if not inMath:
        result.addIf r"\_"
      else:
        result.add c
    else: result.add c
    last = c


import std / strutils
proc itemizeData*(data: string): seq[Item] =
  var el: Item
  for line in data.splitLines:
    if line.startsWith("-"): # item at top level
      if el.item.len > 0:
        result.add el
        el.item.setLen(0)
        el.level = 0
      el.item.add line
    elif line.startsWith(" ") and not line.strip.startsWith("-") and el.item.len > 0: # continuation
      el.item.add line
    elif line.startsWith(" ") and line.strip.startsWith("-"): # nested el
      if el.item.len > 0:
        result.add el
        el.item.setLen(0)
        el.level = 0
      let level = line.find(chars = {'-'}) div 2 # two spaces == 1 level
      el.item.add (line & "\n")
      el.level = level
    else:
      echo "[INFO] No itemize section found in line: ", line
  if el.item.len > 0:
    result.add el

proc toItemize*(itms: seq[Item]): string =

  proc process(s: string): string =
    s.strip(chars = {' ', '-'}) #.escapeLatex()

  var itemizeSec: string
  var level = -1
  for el in itms:
    if el.level > level: # new itemize
      itemizeSec.add "\n\\begin{itemize}\n"
    if el.level < level: # end last
      itemizeSec.add "\n\\end{itemize}\n"
    itemizeSec.add "\\item " & (el.item.process()) & "\n"
    level = el.level
  while level >= 0:
    itemizeSec.add "\n\\end{itemize}\n"
    dec level

  result = itemizeSec
