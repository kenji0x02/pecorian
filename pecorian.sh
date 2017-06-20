
pecorian_cmd() {
  # 配列に半角スペースを許す
  IFS_BACKUP=$IFS
  IFS=$'\n'

  # 1) select scope
  local scope_current_dir="Current dir"
  local scope_current_dir_below2="Current dir below depth 2"
  local scope_current_dir_below3="Current dir below depth 3"
  local scope_current_dir_below_all="Current dir below depth all"
  local scope_favorite="Favorite"
  local scope_recent="Recently used"
  local scope_git_rep="Git repository(ghq)"
  local scope_process="Process"
  local scope_path="Path"
  local scope_trush="Trush"
  local scope_docker_container="Docker a container"
  local scope_docker="Docker containers/images"

  local scope_list
  scope_list=()
  scope_list=(${scope_list[@]} $scope_current_dir)
  scope_list=(${scope_list[@]} $scope_current_dir_below2)
  scope_list=(${scope_list[@]} $scope_current_dir_below3)
  scope_list=(${scope_list[@]} $scope_current_dir_below_all)
  scope_list=(${scope_list[@]} $scope_favorite)
  scope_list=(${scope_list[@]} $scope_recent)
  scope_list=(${scope_list[@]} $scope_git_rep)
  scope_list=(${scope_list[@]} $scope_process)
  scope_list=(${scope_list[@]} $scope_path)
  if [ "$COMSPEC" != "" ] || [ `uname` = "Darwin" ]; then # WindowまたはMacでのみ表示
    scope_list=(${scope_list[@]} $scope_trush)
  fi
  # dockerコマンドが存在した場合のみ表示
  # whichコマンドで探すよりも組込みコマンドのtypeの方が速いらしい
  # http://qiita.com/kawaz/items/1b61ee2dd4d1acc7cc94
  if type "docker" > /dev/null 2>&1; then
    scope_list=(${scope_list[@]} $scope_docker_container)
    scope_list=(${scope_list[@]} $scope_docker)
  fi

  local scope="$( for s in ${scope_list[@]}; do echo $s; done | peco --prompt="scope >")"

  # 2) select target
  # todo: 新規作成のフロー新規作成ファイル名を指定？？
  local target=""
  local post_command=""
  case $scope in
    $scope_current_dir)
      # カレントディレクトリ[.]と親ディレクトリ[..]を表示しない(Aオプション)
      target="$( \ls -AF --group-directories-first | peco --prompt="target >")" # エイリアスを外して、ディレクトリは/をつけて表示(Fオプション)
      ;;
    $scope_current_dir_below2)
      # findは難しい、http://takuya-1st.hatenablog.jp/entry/20110918/1316338219
      target="$( find . -maxdepth 2 -type d -name '.git' -prune -o -print | peco --prompt="target >")"
      ;;
    $scope_current_dir_below3)
      target="$( find . -maxdepth 3 -type d -name '.git' -prune -o -print | peco --prompt="target >")"
      ;;
    $scope_current_dir_below_all)
      target="$( find . -type d -name '.git' -prune -o -print | peco --prompt="target >")"
      ;;
    $scope_favorite)
      target="$( cat ~/.dir_favorite | head -n $((LINES - 3)) | peco --prompt="target >")"
      ;;
    $scope_recent)
      # とりあえず1行捨てるバージョンで表示
      target="$( tac ~/.dir_history | sed '1d' | awk '!a[$0]++' | head -n $((LINES - 3)) | peco --prompt="target >")"
      ;;
    $scope_git_rep)
      target="$( ghq list | peco --prompt="target >")"
      ;;
    $scope_process)
      if [ "$COMSPEC" != "" ]; then
        target="$( tasklist | peco --prompt="target >"| awk '{print $2}')"
      else
        target="$( ps aux | peco --prompt="target >"| awk '{print $2}')"
      fi
      ;;
    $scope_path)
      target="$( echo $PATH | tr ':' '\n' | peco --prompt="target >")"
      ;;
    $scope_trush)
      target=""
      ;;
    $scope_docker_container)
      if [ -z "$(docker ps -a --format {{.ID}})" ]; then
        echo "Error. There is no containers."
        return 1
      fi
      # 空白カラムが存在するケースがあるのでNAMES属性はとれない
      target="$( docker ps -a | tail -n +2 | peco --prompt="target >" | cut -d" " -f1 )"
      ;;
    $scope_docker)
      local docker_targets_list
      docker_targets_list=()
      # docker-composeが使える場合のみdocker-composeで管理されているコンテナを対象とする
      if [ -e "docker-compose.yml" ] || [ -e "docker-compose.yaml" ]; then
        docker_targets_list=(${docker_targets_list[@]} "containers managed by Compose")
      fi
      docker_targets_list=(${docker_targets_list[@]} "containers stopped")
      docker_targets_list=(${docker_targets_list[@]} "containers all")
      docker_targets_list=(${docker_targets_list[@]} "images that is not used in all containers")
      docker_targets_list=(${docker_targets_list[@]} "images that is not tagged (i.e. <none>:<none>)")
      scope_list=(${scope_list[@]} $scope_current_dir)
      target="$( for s in ${docker_targets_list[@]}; do echo $s; done | peco --prompt="target >")"
      ;;
    *) # 上記以外
      target="$( \ls -AF --group-directories-first | peco --prompt="target >")" # エイリアスを外して、ディレクトリは/をつけて表示
  esac

  # 3) select action
  local action_list
  action_list=()
  # todo: ドットファイルがディレクトリとして認識される
  local eval_target="$(eval "echo $target")"
  if [ $scope = $scope_git_rep ]; then
    action_list=(${action_list[@]} "cd")
    action_list=(${action_list[@]} "cd && open with explorer")
    action_list=(${action_list[@]} "cd && git pull origin master")
    action_list=(${action_list[@]} "open with browser")
  elif [ $scope = $scope_process ]; then action_list=(${action_list[@]} "kill")
    action_list=(${action_list[@]} "show detail")
  elif [ $scope = $scope_trush ]; then
    action_list=(${action_list[@]} "remove")
    action_list=(${action_list[@]} "open with explorer")
  elif [ $scope = $scope_docker_container ]; then
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
  elif [ $scope = $scope_docker ]; then
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
  elif [ -d $eval_target ]; then
    action_list=(${action_list[@]} "cd")
    action_list=(${action_list[@]} "ls -al")
    action_list=(${action_list[@]} "rm -rf")
    action_list=(${action_list[@]} "mv")
    action_list=(${action_list[@]} "cp")
    # 空白文字列を含む場合は""で囲う
    if [[ "$target" =~ " " ]]; then
      target="\"${target}\""
    fi
  else
    # ディレクトリじゃないときのコマンドリスト
    local action_list=(open vi mv rm cp ls cat less) # openコマンドは自前で実装
  fi

  local action="$(for e in ${action_list[@]}; do echo $e; done | peco --prompt="action >")"

  if [ $scope = $scope_git_rep ]; then
    if [ $action = "cd && open with explorer" ]; then
      local ghq_root=""
      if [ "$COMSPEC" != "" ]; then
        ghq_root="$( cygpath `ghq root` )" # Windowsの場合はスラッシュ表記に変更
        post_command="&& explorer ."
      else
        ghq_root="`ghq root`"
        post_command="&& open ."
      fi
      target=${ghq_root}/${target}
      action="cd"
    elif [ $action = "cd && git pull origin master" ]; then
      local ghq_root=""
      if [ "$COMSPEC" != "" ]; then
        ghq_root="$( cygpath `ghq root` )" # Windowsの場合はスラッシュ表記に変更
      else
        ghq_root="`ghq root`"
      fi
      target=${ghq_root}/${target}
      action="cd"
      post_command="&& git pull origin master"
    elif [ $action = "cd" ]; then
      local ghq_root=""
      if [ "$COMSPEC" != "" ]; then
        ghq_root="$( cygpath `ghq root` )" # Windowsの場合はスラッシュ表記に変更
      else
        ghq_root="`ghq root`"
      fi
      target=${ghq_root}/${target}
    elif [ $action = "open with browser" ]; then
      # http://qiita.com/itkrt2y/items/0671d1f48e66f21241e2
      target="$( echo $target | cut -d "/" -f 2,3 )"
      action="hub browse"
    fi
  elif [ $scope = $scope_process ]; then
    if [ $action = "kill" ]; then
      if [ "$COMSPEC" != "" ]; then
        local action="taskkill -f -pid"
      else
        local action="kill"
      fi
    elif [ $action = "show detail" ]; then
      if [ "$COMSPEC" != "" ]; then
        local action="wmic process where ProcessID=${target} get Name,ProcessId,CommandLine /format:list"
      else
        local action="sudo ls --color -al /proc/${target}"
      fi
      target=""
    fi
  elif [ $scope = $scope_trush ]; then
    if [ $action = "remove" ]; then
      if [ "$COMSPEC" != "" ]; then
        local action='rm -R /c/\$Recycle.Bin/ 2>/dev/null'
      else
        local action='rm -rf ~/.Trash/'
      fi
    elif [ $action = "open with explorer" ]; then
      if [ "$COMSPEC" != "" ]; then
        # shellコマンドで特殊フォルダをエクスプローラーで開く
        local action="explorer shell:RecycleBinFolder"
      else
        local action="open ~/.Trash/"
      fi
    fi
  elif [ $scope = $scope_docker_container ]; then
    if [ $action = "start" ]; then
      local action="docker start"
    elif [ $action = "stop" ]; then
      local action="docker stop"
    elif [ $action = "log" ]; then
      local action="docker logs -tf" # -t:時間も表示, -f(--folow):ログを出力し続ける
    elif [ $action = "exec (run a new command in a running container)" ]; then
      local action="docker exec -it" # -i:interactive, -t:tty
      post_command="ps -aux" # 例)プロセスを表示
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
  elif [ $scope = $scope_docker ]; then
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
  fi

  # 4) return command
  echo "${action} ${target} ${post_command}"
  IFS=$IFS_BACKUP

  return
}

