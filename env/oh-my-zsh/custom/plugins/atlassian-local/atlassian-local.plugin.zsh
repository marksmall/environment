# Personal acli (Atlassian CLI) aliases and functions for Oh My Zsh — Jira
# Cloud only for now. Every alias/function is prefixed "at" (Atlassian),
# matching the gh-local convention of prefixing with a short tool mnemonic
# rather than reusing the bare command. See ~/acli-cheatsheet.md for the full
# command reference this is built on top of.

alias atw='acli jira auth status'
alias atl='acli jira auth login --web'

# View
alias atvf='acli jira workitem view'         # atvf KEY-123, plain default-fields view
alias atvj='acli jira workitem view --json'  # atvj KEY-123, machine-readable
alias atb='acli jira workitem view --web'    # atb KEY-123, open in browser

alias asta='acli jira workitem search --jql "assignee = currentUser() AND resolution = Unresolved ORDER BY updated DESC"'

astap() {
  local project="${1:?usage: astap <project> e.g. DCP, DSP3 etc}"

  acli jira workitem search --jql "project = ${project} AND assignee = currentUser() AND resolution = Unresolved ORDER BY updated DESC"
}

# Trimmed, colourised view — the one used most, so it gets the short name.
# jq colourises JSON output by default when stdout is a terminal (and honours
# NO_COLOR), so this needs no colour handling of its own. Colour is by JSON
# type (keys/strings/numbers), not by Jira's semantic status colour.
# description is flattened to one line in the JSON (a JSON string can't hold
# a real line break — it would just show as literal \n text), then rendered
# a second time below as plain text with real paragraph breaks, hardBreak
# lines, and bullet/numbered list structure, since that needs to live
# outside the JSON to be visible at all.
# Usage: atv <KEY>
atv() {
  local key="${1:?Usage: atv <KEY>}"
  local json
  json=$(acli jira workitem view "$key" \
    --fields "key,issuetype,summary,status,assignee,priority,description,issuelinks" \
    --json)
  jq '{
    key,
    type: .fields.issuetype.name,
    summary: .fields.summary,
    status: .fields.status.name,
    assignee: (.fields.assignee.displayName // "Unassigned"),
    priority: (.fields.priority.name // null),
    description: ([.fields.description | .. | .text? // empty] | join(" ")),
    links: [.fields.issuelinks[]? | {
      rel: (if .outwardIssue then .type.outward else .type.inward end),
      key: ((.outwardIssue // .inwardIssue).key),
      status: ((.outwardIssue // .inwardIssue).fields.status.name),
      summary: ((.outwardIssue // .inwardIssue).fields.summary)
    }]
  }' <<< "$json"
  echo
  echo "Description:"
  local desc
  desc=$(jq -r '
    def render:
      (.type // "") as $t |
      if $t == "text" then (.text // "")
      elif $t == "hardBreak" then "\n"
      elif $t == "paragraph" then
        ([.content[]? | render] | join(" ") | gsub(" ?\n ?"; "\n"))
      elif $t == "bulletList" then
        ((.content // []) | map("- " + render) | join("\n"))
      elif $t == "orderedList" then
        ((.content // []) | to_entries | map("\(.key+1). " + (.value | render)) | join("\n"))
      elif $t == "listItem" then
        ((.content // []) | to_entries | map(
            (.value | render) as $r |
            if .key == 0 then $r else ($r | gsub("\n"; "\n  ")) end
          ) | join("\n"))
      else
        ((.content // []) | map(render) | join("\n\n"))
      end;
    ([.fields.description.content[]? | render | sub("^\n+";"") | sub("\n+$";"")] | join("\n\n"))
    | gsub("\n{3,}"; "\n\n")
  ' <<< "$json")

  # Tickets here usually pair two separate conventions: the Connextra user
  # story template (As a/I want/So that — informal prose, no real grammar)
  # for the narrative, and Gherkin (Given/When/Then/And/But — a real,
  # tool-parsed grammar) for acceptance criteria. Highlight both sets of
  # keywords plus bullet markers and short label lines like "User story:" —
  # gated on -t 1/NO_COLOR the same way jq gates its own colour, since raw
  # ANSI codes would otherwise pollute output piped to a file or another
  # command.
  if [[ -t 1 && -z "$NO_COLOR" ]]; then
    sed -E $'
      s/^([[:space:]]*)(- )(Given|When|Then|And|But)\\b/\\1\\2\x1b[1;36m\\3\x1b[0m/
      s/^([[:space:]]*)(As a|I want|So that)\\b/\\1\x1b[1;36m\\2\x1b[0m/
      s/^([[:space:]]*)(- )([^:]*)$/\\1\x1b[2m\\2\x1b[0m\\3/
      s/^([A-Za-z ]+):$/\x1b[1m&\x1b[0m/
    ' <<< "$desc"
  else
    echo "$desc"
  fi
}

# Comments
# Plain-table output wraps badly in a terminal for anything but the shortest
# comments — pull JSON and trim to author/body instead. Only surface
# visibility when a comment is actually restricted, not on every row.
# Usage: atcl <KEY>
atcl() {
  local key="${1:?Usage: atcl <KEY>}"
  acli jira workitem comment list --key "$key" --json | jq '
    .comments[] | {author, body} + (if .visibility != "public" then {visibility: .visibility} else {} end)
  '
}

# Usage: atc <KEY> <comment text...>
atc() {
  local key="${1:?Usage: atc <KEY> <comment text...>}"
  shift
  acli jira workitem comment create --key "$key" --body "$*"
}

# Look up an account ID off a ticket's current assignee — the easiest way to
# get an ID to hand to attag, since acli has no dedicated user-lookup command.
# Usage: atacc <KEY>
atacc() {
  local key="${1:?Usage: atacc <KEY>}"
  acli jira workitem view "$key" --fields assignee --json | jq -r '.fields.assignee.accountId'
}

# Tag someone in a comment by account ID, without hand-building the
# [~accountid:...] mention markup yourself.
# Usage: attag <KEY> <accountId> <comment text...>
attag() {
  local key="${1:?Usage: attag <KEY> <accountId> <comment text...>}"
  local account="${2:?Usage: attag <KEY> <accountId> <comment text...>}"
  shift 2
  acli jira workitem comment create --key "$key" --body "[~accountid:${account}] $*"
}

# Tag someone by name instead of account ID — acli has no user-lookup
# command, so this calls the Jira Cloud REST API directly (the same
# user/search endpoint the browser's @mention picker uses) with
# $ATLASSIAN_CLI_TOKEN. That endpoint does loose token matching (querying
# "Dexter Hill" also returns every "Hill" in the org), so results are
# filtered down to an exact, case-insensitive displayName match before
# picking an account ID — ambiguous or missing matches print candidates
# and bail rather than guessing who to tag.
# Usage: attagn <KEY> <full name> <comment text...>
attagn() {
  local key="${1:?Usage: attagn <KEY> <full name> <comment text...>}"
  local name="${2:?Usage: attagn <KEY> <full name> <comment text...>}"
  shift 2
  local site email tmp http_code
  site=$(acli jira auth status | awk '/Site:/{print $2}')
  email=$(acli jira auth status | awk '/Email:/{print $2}')
  tmp=$(mktemp)
  http_code=$(curl -s -G --data-urlencode "query=${name}" \
    -u "${email}:${ATLASSIAN_CLI_TOKEN}" -H "Accept: application/json" \
    -o "$tmp" -w '%{http_code}' \
    "https://${site}/rest/api/3/user/search")
  if [[ "$http_code" != "200" ]]; then
    echo "attagn: user search failed (HTTP $http_code)" >&2
    rm -f "$tmp"
    return 1
  fi

  local exact exact_count account_id
  exact=$(jq --arg q "$name" '[.[] | select(.displayName | ascii_downcase == ($q|ascii_downcase))]' "$tmp")
  exact_count=$(jq 'length' <<< "$exact")

  if [[ "$exact_count" -eq 0 ]]; then
    echo "attagn: no exact match for '${name}'. Closest results:" >&2
    jq -r '.[:10][] | "  \(.displayName)  <\(.emailAddress // "no email")>"' "$tmp" >&2
    rm -f "$tmp"
    return 1
  elif [[ "$exact_count" -gt 1 ]]; then
    echo "attagn: multiple users named '${name}' — use attag with an account ID instead:" >&2
    jq -r '.[] | "  \(.displayName)  <\(.emailAddress // "no email")>  \(.accountId)"' <<< "$exact" >&2
    rm -f "$tmp"
    return 1
  fi

  account_id=$(jq -r '.[0].accountId' <<< "$exact")
  rm -f "$tmp"
  acli jira workitem comment create --key "$key" --body "[~accountid:${account_id}] $*"
}

# Assignment
alias atme='acli jira workitem assign --assignee @me --key'   # atme KEY-123, self-assign
alias atun='acli jira workitem assign --remove-assignee --key'   # atun KEY-123, unassign

# Usage: ata <KEY> <assignee email or accountId>
ata() {
  local key="${1:?Usage: ata <KEY> <assignee>}"
  local assignee="${2:?Usage: ata <KEY> <assignee>}"
  acli jira workitem assign --key "$key" --assignee "$assignee"
}

# Transitions
# Usage: att <KEY> <status>
att() {
  local key="${1:?Usage: att <KEY> <status>}"
  local status="${2:?Usage: att <KEY> <status>}"
  acli jira workitem transition --key "$key" --status "$status"
}

# Search
# resolution = Unresolved isn't enough on its own — some workflows here
# transition tickets to Done without ever setting the resolution field, so
# status != Done is a required backstop, not a belt-and-braces extra.
alias atsme='acli jira workitem search --jql "assignee = currentUser() AND resolution = Unresolved AND status != Done" --paginate'

# Usage: atsu <email or accountId>
atsu() {
  local who="${1:?Usage: atsu <email or accountId>}"
  acli jira workitem search --jql "assignee = '${who}' AND resolution = Unresolved AND status != Done" --paginate
}

# Usage: atsp <PROJECT> <text...>
atsp() {
  local project="${1:?Usage: atsp <PROJECT> <text...>}"
  shift
  local text="${*:?Usage: atsp <PROJECT> <text...>}"
  acli jira workitem search --jql "project = '${project}' AND (summary ~ '${text}' OR description ~ '${text}')" --paginate
}

# Usage: ats <raw JQL...>
ats() {
  acli jira workitem search --jql "$*" --paginate
}
