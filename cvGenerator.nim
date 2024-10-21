import orgparser, latexdsl_nochecks
import std / [macros, options, strutils]

import ./cv_types, ./backend_altacv

iterator desiredSubsections(org: OrgNode): OrgNode =
  ## Yields all subsections that are _not_ tagged with `:noexport:`.
  for e in subsections(org):
    if not e.hasTag("noexport"):
      yield e

macro setFields(cv, p, org: typed, prefix: string): untyped =
  let typ = p.getTypeImpl()
  doAssert typ[2].kind == nnkRecList
  result = newStmtList()
  for el in typ[2]: ## RecList
    let f = el[0]
    let target = ident(prefix.strVal & f.strVal)
    result.add quote do:
      let t = `cv`.cfg.`target`
      let opt = `org`.getProperty(t)
      if opt.isSome:
        `p`.`f` = $(opt.get.value)

  echo result.repr

proc personalInfo(cv: var CV) =
  let pers = findSection(cv.org, cv.cfg.pKey)
  let pList = pers.propertyList()
  var p: PersonalInfo
  cv.setFields(p, pList, "p")
  cv.personal = p
  cv.fieldsAdded.incl cfPersonal

proc education(cv: var CV) =
  let eduOrg = findSection(cv.org, cv.cfg.eKey)
  # iterate all subsections of education
  var edu: Education
  for e in desiredSubsections(eduOrg):
    var entry: EducationEntry
    var p: EducationEntryPList
    let pList = e.propertyList()
    cv.setFields(p, pList, "e")

    # get the description
    entry.title = $e.sec.title
    entry.pList = p
    entry.description = $e.getBody()

    edu.add entry
  cv.education = edu
  cv.fieldsAdded.incl cfEducation

proc work(cv: var CV) =
  let workOrg = findSection(cv.org, cv.cfg.wKey)
  # iterate all subsections of education
  var work: Work
  for e in desiredSubsections(workOrg):
    var entry: WorkEntry
    var p: WorkEntryPList
    let pList = e.propertyList()
    cv.setFields(p, pList, "w")

    # get the description
    entry.title = $e.sec.title
    entry.pList = p
    entry.description = $e.getBody()

    work.add entry
  cv.work = work
  cv.fieldsAdded.incl cfWork

proc languages(cv: var CV) =
  let langOrg = findSection(cv.org, cv.cfg.lKey)
  # iterate all subsections of education
  var lang: Languages
  # Get mother tongue
  let pList = langOrg.propertyList()
  let mOpt = pList.getProperty("MotherTongue")
  if mOpt.isNone:
    raise newException(ValueError, "No mother tongue set. Set a mother tongue to the properties " &
      "of the " & $cv.cfg.lKey & " section with `:MotherTongue:` as the key.")
  lang.motherTongue = $mOpt.get.value # must exist
  for e in desiredSubsections(langOrg):
    var entry: Language
    var p: LanguagePList
    let pList = e.propertyList()
    cv.setFields(p, pList, "l")

    # get the description
    entry.title = $e.sec.title
    entry.pList = p

    lang.foreign.add entry

  cv.langs = lang
  cv.fieldsAdded.incl cfLangs

proc projects(cv: var CV) =
  let projOrg = findSection(cv.org, cv.cfg.projKey)
  # iterate all subsections of education
  var proj: Projects
  for e in desiredSubsections(projOrg):
    var entry: Project
    var p: ProjectPList
    let pList = e.propertyList()
    cv.setFields(p, pList, "proj")

    # get the description
    entry.title = $e.sec.title
    entry.pList = p
    entry.description = $e.getBody()

    proj.add entry

  cv.projects = proj
  cv.fieldsAdded.incl cfProjects

proc addSkillSection(sec: OrgNode, name: string): SkillSection =
  result = SkillSection(section: name)
  let body = sec.getBodyText()
  for (skill, _) in ($body).itemizeData():
    result.skills.add skill.strip(chars = {' ', '-'})

proc skills(cv: var CV, includeSections: seq[string] = @[]) =
  let skillOrg = findSection(cv.org, cv.cfg.skillKey)
  # iterate all subsections of education
  var skills: Skills
  # First check the body of `Skills` itself
  skills.add addSkillSection(skillOrg, cv.cfg.skillKey)

  for e in desiredSubsections(skillOrg):
    let title = $e.getTitle()
    if includeSections.len == 0 or title in includeSections:
      skills.add addSkillSection(e, title)

  cv.skills = skills
  cv.fieldsAdded.incl cfSkills

const path = "/home/basti/org/Documents/CV_data/CV_data_october2024.org"

var cv = initCV(path, bkAltaCV)
cv.cfg.projIncludeDates = false
cv.cfg.projKey = "Selected Projects"
cv.personalInfo()
cv.education()
cv.work()
cv.languages()
cv.projects()
cv.skills(@["Programming languages", "Other"])

let cvTex = cv.genCV()
compile("/tmp/test_cv.tex", cvTex, fullBody = true)
