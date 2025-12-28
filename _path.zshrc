#!/usr/bin/env zsh

function define_path() {
  local base_path="/usr/local/sbin:/usr/local/bin:/bin:/usr/sbin:/sbin:/usr/bin"
  export PATH="${base_path}"

  if [ "$(uname)" = "Darwin" ]; then
    export PATH="/opt/homebrew/bin:/Applications/Xcode.app/Contents/Developer/usr/bin:${PATH}"
    [ -f "${HOME}/src/z.lua/z.lua" ] && eval "$(lua ${HOME}/src/z.lua/z.lua --init zsh enhanced)"
  elif [ "$(uname)" = "Linux" ]; then
    [ -f "/usr/bin/lua" ] && eval "$(lua ${HOME}/src/z.lua/z.lua --init zsh enhanced)"
  fi

  [ -d "${GOPATH}" ] && export PATH="${PATH}:${GOPATH}/bin"
  [ -d "${HOME}/.fvm" ] && export PATH="${HOME}/.fvm/bin:${HOME}/.fluvio/bin:${PATH}"
}

# Initialize path
define_path
  export PATH="${HOME}/.bun/bin:/Applications/IntelliJ IDEA.app/Contents/MacOS/:$PATH"
}

# Initialize path
define_path 
