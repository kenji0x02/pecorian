pecorian_tmux_cmd() {

  # 2) select target
  local targets_list
  targets_list=()
  # docker-composeが使える場合のみdocker-composeで管理されているコンテナを対象とする

  local targets="`tmux ls`"
  local create_new_session="New Session:"
  if [ -z $targets ]; then
    targets="${create_new_session}"
  else
    targets="${targets}\n${create_new_session}"
  fi
  local target="$( echo $targets | pip_peco target | cut -d: -f1)"
  # common process
  local post_command=""
  [ -z "$target" ] && pecorian_abort

  # 3) select action
  if [ $target != "New Session" ]; then
    local action_list
    action_list=()
    action_list=(${action_list[@]} "attach")
    action_list=(${action_list[@]} "rename")
    action_list=(${action_list[@]} "exit")
    # common process ("action" is always selected from array)
    local action="$(for e in ${action_list[@]}; do echo $e; done | pip_peco action )"
    [ -z "$action" ] && pecorian_abort
  fi

  # 4) create command
  if [ $target = "New Session" ]; then
    action="tmux"
    target=""
  elif [ $action = "attach" ]; then
      action="tmux a -t"
  fi

  # 5) return command
  echo "${action} ${target} ${post_command}"

  return
}
