pecorian_path_cmd() {

  # 2) select target
  local target="$( echo $PATH | tr ':' '\n' | pip_peco target )"
  # common process
  local post_command=""
  [ -z "$target" ] && pecorian_abort

  # 3) select action
  local action_list
  action_list=()
  action_list=(${action_list[@]} "cd")
  action_list=(${action_list[@]} "ls -al")
  # common process ("action" is always selected from array)
  local action="$(for e in ${action_list[@]}; do echo $e; done | pip_peco action )"
  [ -z "$action" ] && pecorian_abort

  # 4) create command
  # 空白文字列を含む場合は""で囲う
  if [[ "$target" =~ " " ]]; then
    target="\"${target}\""
  fi

  # 5) return command
  echo "${action} ${target} ${post_command}"

  return
}