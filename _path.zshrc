#!/usr/bin/env zsh

function define_path() {
  local base_path="/usr/local/sbin:/usr/local/bin:/bin:/usr/sbin:/sbin:/usr/bin"
  export PATH="${base_path}"

  if [ "$(uname)" = "Darwin" ]; then
    export PATH="/opt/homebrew/bin:/Applications/Xcode.app/Contents/Developer/usr/bin:${PATH}:${HOME}/.cargo/bin"
    [ -f "${HOME}/src/z.lua/z.lua" ] && eval "$(lua ${HOME}/src/z.lua/z.lua --init zsh enhanced)"
  elif [ "$(uname)" = "Linux" ]; then
    [ -f "/usr/bin/lua" ] && eval "$(lua ${HOME}/src/z.lua/z.lua --init zsh enhanced)"
  fi

  [ -d "${GOPATH}" ] && export PATH="${PATH}:${GOPATH}/bin"
}

# Initialize path
function define_path_krew() {
  export PATH="${HOME}/.bun/bin:/Applications/IntelliJ IDEA.app/Contents/MacOS/:$PATH"
  export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
}


# Initialize path
define_path
define_path_krew
mise use -g node@23
