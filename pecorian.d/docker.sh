pecorian_docker_cmd() {

  # 2) select target
  local targets_list
  targets_list=()
  # docker-composeが使える場合のみdocker-composeで管理されているコンテナを対象とする
  if [ -e "docker-compose.yml" ] || [ -e "docker-compose.yaml" ]; then
    targets_list=(${targets_list[@]} "containers managed by Compose")
  fi
  targets_list=(${targets_list[@]} "containers stopped")
  targets_list=(${targets_list[@]} "containers all")
  targets_list=(${targets_list[@]} "images that is not used in all containers")
  targets_list=(${targets_list[@]} "images that is not tagged (i.e. <none>:<none>)")
  target="$( for s in ${targets_list[@]}; do echo $s; done | pip_peco target )"
  # common process
  local post_command=""
  [ -z "$target" ] && pecorian_abort

  # 3) select action
  local action_list
  action_list=()
  if [ $target = "containers managed by Compose" ]; then
    action_list=(${action_list[@]} "build, create and start") # サービスを構築(build)して、コンテナ作成(create)と開始(start)
    action_list=(${action_list[@]} "logs") # 関係するコンテナのすべての出力を表示
    action_list=(${action_list[@]} "stop")
    action_list=(${action_list[@]} "remove")
    action_list=(${action_list[@]} "down(stop and rm service) and delete images") # 関係するコンテナをまとめて停止して削除
    action_list=(${action_list[@]} "ps") # 関係するコンテナの一覧表示
    action_list=(${action_list[@]} "restart") # 関係するコンテナの再起動
  else
    action_list=(${action_list[@]} "remove")
  fi
  # common process ("action" is always selected from array)
  local action="$(for e in ${action_list[@]}; do echo $e; done | pip_peco action )"
  [ -z "$action" ] && pecorian_abort

  # 4) create command
  if [ $target = "containers managed by Compose" ]; then
    if [ $action = "build, create and start" ]; then
      action="docker-compose up -d --build"
    elif [ $action = "logs" ]; then
      action="docker-compose logs -tf" # t: time, f: follow
    elif [ $action = "stop" ]; then
      action="docker-compose stop"
    elif [ $action = "remove" ]; then
      action="docker-compose rm"
    elif [ $action = "down(stop and rm service) and delete images" ]; then 
      action="docker-compose down --rmi all"
    elif [ $action = "ps" ]; then
      action="docker-compose ps"
    elif [ $action = "restart" ]; then
      action="docker-compose restart"
    else
      action=""
    fi
    target=""
  else
    if [ $action = "remove" ]; then
      if [ $target = "containers stopped" ]; then
        local action="docker container prune" #prune: 刈り込む
      elif [ $target = "containers all" ]; then
        local action='docker rm -f $(docker ps -aq)'
      elif [ $target = "images that is not used in all containers" ]; then
        local action="docker images prune" #prune: 刈り込む
      elif [ $target = "images that is not tagged (i.e. <none>:<none>)" ]; then
        local action='docker rmi $(docker images -aqf 'dangling=true')' #dangling: ぶら下がる
      else
        local action=""
      fi
      target=""
    fi
  fi

  # 5) return command
  echo "${action} ${target} ${post_command}"

  return
}