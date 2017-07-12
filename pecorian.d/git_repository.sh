pecorian_git_repository_cmd() {

  # 2) select target
  local target="$( ghq list | pip_peco target )"
  # common process
  local post_command=""
  [ -z "$target" ] && pecorian_abort

  # 3) select action
  local action_list
  action_list=()
  action_list=(${action_list[@]} "cd")
  action_list=(${action_list[@]} "cd && open with explorer")
  action_list=(${action_list[@]} "cd && git pull origin master")
  if type "hub" > /dev/null 2>&1; then
    action_list=(${action_list[@]} "open with browser")
  fi
  # common process ("action" is always selected from array)
  local action="$(for e in ${action_list[@]}; do echo $e; done | pip_peco action )"
  [ -z "$action" ] && pecorian_abort

  # 4) create command
  if [ $action = "cd && open with explorer" ]; then
    local ghq_root=""
    if pecorian_is_windows_os; then
      # Windowsの場合はスラッシュ表記に変更
      ghq_root="$( cygpath `ghq root` )"
      post_command="&& explorer ."
    else
      ghq_root="`ghq root`"
      post_command="&& open ."
    fi
    target=${ghq_root}/${target}
    action="cd"
  elif [ $action = "cd && git pull origin master" ]; then
    local ghq_root=""
    if pecorian_is_windows_os; then
      ghq_root="$( cygpath `ghq root` )"
    else
      ghq_root="`ghq root`"
    fi
    target=${ghq_root}/${target}
    action="cd"
    post_command="&& git pull origin master"
  elif [ $action = "cd" ]; then
    local ghq_root=""
    if pecorian_is_windows_os; then
      ghq_root="$( cygpath `ghq root` )"
    else
      ghq_root="`ghq root`"
    fi
    target=${ghq_root}/${target}
  elif [ $action = "open with browser" ]; then
    # http://qiita.com/itkrt2y/items/0671d1f48e66f21241e2
    target="$( echo $target | cut -d "/" -f 2,3 )"
    action="hub browse"
  fi

  # 5) return command
  echo "${action} ${target} ${post_command}"

  return
}