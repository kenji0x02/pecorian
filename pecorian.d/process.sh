pecorian_process_cmd() {

  # 2) select target
  local target=""
  if pecorian_is_windows_os; then
    target="$( tasklist | pip_peco target | awk '{print $2}')"
  else
    target="$( ps aux | pip_peco target | awk '{print $2}')"
  fi
  # common process
  local post_command=""
  [ -z "$target" ] && pecorian_abort

  # 3) select action
  local action_list
  action_list=()
  if pecorian_is_mac_os; then
    action_list=(${action_list[@]} "kill")
  else
    action_list=(${action_list[@]} "kill")
    action_list=(${action_list[@]} "show detail")
  fi
  # common process ("action" is always selected from array)
  local action="$(for e in ${action_list[@]}; do echo $e; done | pip_peco action )"
  [ -z "$action" ] && pecorian_abort

  # 4) create command
  if [ $action = "kill" ]; then
    if pecorian_is_windows_os; then
      local action="taskkill -f -pid"
    else
      local action="kill"
    fi
  elif [ $action = "show detail" ]; then
    if pecorian_is_windows_os; then
      local action="wmic process where ProcessID=${target} get Name,ProcessId,CommandLine /format:list"
    else
      local action="sudo ls --color -al /proc/${target}"
    fi
    target=""
  fi

  # 5) return command
  echo "${action} ${target} ${post_command}"

  return
}