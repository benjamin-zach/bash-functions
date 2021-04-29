# use this file to run your own startup commands for msys2 bash'

# To add a new vendor to the path, do something like:
# export PATH=${CMDER_ROOT}/vendor/whatever:${PATH}

# UnRESULT this to have the ssh agent load with the first bash terminal
# . "${CMDER_ROOT}/vendor/lib/start-ssh-agent.sh"

alias mvn='mvn -s /c/Daten/maven_settings.xml'

prevBranchFile() {
    echo $(git rev-parse --show-toplevel)/.git/PREV_BRANCH
}

greturn() {
  if [ $# == 1 ]; then
    git checkout $(sed "$1q;d" $(prevBranchFile))
  fi 
}

echoMissingBranchHistory() {
    echo "You don't have a branch history yet. Try checking out different branches using"
    echo ''
    echo -e ' \t git checkout <branch_name> '
    echo ''
    echo 'to build up a branch history'

}

# This is a wrapper function to add some shortcuts to git, such as:
#    - 'git checkout return' checks out the branch that has been checked out before the current branch
#    - 'git checkout return <n>' checks out the nth branch that has been checked out before the current branch
#    - 'git branch current' returns the name of the current branch
#    - 'git push publish' is a wrapper for 'git push --set-upstream origin $(git branch current)'
#    - 'git branch -gf <JIRA_commit_comment>' generates a feature branch name from the JIRA commit comment 
#                                             and checks out a new branch of this name
#    - 'git branch -gb <JIRA_commit_comment>' generates a bugfix  branch name from the JIRA commit comment 
#                                             and checks out a new branch of this name
git() {
#  if [ -d .git ]; then
    if [[ "$1" == checkout ]] && [[ "$2" == "return" ]] && [[ $# == 2 ]]; then
      if [ -f "$(git rev-parse --show-toplevel)/.git/PREV_BRANCH" ]; then
        let n=0
        while read currentLine; do
          if [ $n -ne 0 ]; then
            echo "$n: $currentLine"
          fi
          let n++
        done <$(prevBranchFile)
        if [[ n -le 1 ]]; then
          echoMissingBranchHistory
        else
          read  -n 1 -p "Select branch to checkout: " line
          echo ""
          let line++
          greturn "${line}"
        fi
      else
        echoMissingBranchHistory
      fi
    elif [[ "$1" == checkout ]] && [[ "$2" == "return" ]] && [[ $# == 3 ]]; then
      let n=$3+1
      greturn "$n"
    elif [[ "$1" == checkout ]] && [[ $# -ge 2 ]] && [[ $# -le 3 ]]; then
      echo "${@: -1}" >> temp
      let n=1
      while read currentLine; do
        if [ "${@: -1}" != $currentLine ]; then
          echo $currentLine >> temp
          let n++
          if [ $n == 10 ]; then
            break
          fi
        fi
      done <"$(prevBranchFile)"
      mv temp "$(prevBranchFile)"
      "$(which git)" "$@"
    elif [[ "$1" == branch ]] && [[ "$2" == current ]]; then
      git rev-parse --abbrev-ref HEAD
    elif [[ "$1" == branch ]] && [[ "$2" =~ ^\-g[f|b]{1}$ ]] && [[ $# == 3 ]]; then
      if [ "$2" == "-gf" ]; then
        PREFIX="feature"
      elif [ "$2" == "-gb" ]; then
        PREFIX="bugfix"
      fi
      RESULT=$(echo "$3" | sed "s/[(][^)]*[)]//g" | sed "s/[^ a-zA-Z0-9 -]//g" | sed "s/ \+/-/g" | sed "s/-$//g")
      git checkout -b $PREFIX/$RESULT
    elif [[ "$1" == push ]] && [[ "$2" == publish ]]; then
      git push &> tempfile
      $(cat tempfile | grep set-upstream)
      rm tempfile
#    fi
  else
    "$(which git)" "$@"
  fi
}