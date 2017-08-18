pecorian_docker_container_cmd() {

  # 2) select target
  # 空白カラムが存在するケースがあるのでNAMES属性はとれない
  local target="$( docker ps -a | tail -n +2 | pip_peco target | cut -d" " -f1 )"
  # common process
  local post_command=""
  [ -z "$target" ] && pecorian_abort

  # 3) select action
  local action_list
  action_list=()
  local is_running="$(docker ps -a -f id=$target -f status=running --format {{.ID}})"
  if [ $is_running != "" ]; then
    # 起動しているコンテナに対するアクション
    action_list=(${action_list[@]} "log")
    action_list=(${action_list[@]} "exec (run a new command in a running container)")
    action_list=(${action_list[@]} "attach (connect to PID=1 process)")
    action_list=(${action_list[@]} "top (display the running processes outside the containter)")
    action_list=(${action_list[@]} "stop")
  else
    action_list=(${action_list[@]} "log")
    action_list=(${action_list[@]} "start")
    action_list=(${action_list[@]} "remove")
    action_list=(${action_list[@]} "commit")
  fi
  # common process ("action" is always selected from array)
  local action="$(for e in ${action_list[@]}; do echo $e; done | pip_peco action )"
  [ -z "$action" ] && pecorian_abort

  # 4) create command
  if [ $action = "start" ]; then
    local action="docker start"
  elif [ $action = "stop" ]; then
    local action="docker stop"
  elif [ $action = "log" ]; then
    local action="docker logs -tf" # -t:時間も表示, -f(--folow):ログを出力し続ける
  elif [ $action = "exec (run a new command in a running container)" ]; then
    local action="docker exec -it" # -i:interactive, -t:tty
    # post_command="ps -aux" # 例)プロセスを表示
    post_command="bash" # 例)bashでログイン
  elif [ $action = "attach (connect to PID=1 process)" ]; then
    local action="docker attach"
  elif [ $action = "top (display the running processes outside the containter)" ]; then
    local action="docker top"
    post_command="| unexpand -t20" # 少々見にくいので整形して表示
  elif [ $action = "remove" ]; then
    local action="docker rm"
  elif [ $action = "commit" ]; then
    local action="docker commit"
  fi

  # 5) return command
  echo "${action} ${target} ${post_command}"

  return
}
