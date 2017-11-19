# helper
pip_peco()
{
  peco --prompt="$1 >" --on-cancel error
}

pecorian_abort()
{
  IFS=$PECORIAN_IFS_BACKUP
  exit 1
}

pecorian_is_windows_os()
{
  [ "$COMSPEC" != "" ]
}

pecorian_is_mac_os()
{
  [ `uname` '==' 'Darwin' ]
}

# load pecorian sources
pecorian_config_base()
{
  local go_path=$GOPATH
  if pecorian_is_windows_os; then
    go_path="$( cygpath $GOPATH )" # Windowsの場合はスラッシュ表記に変更
  fi
  echo $go_path/src/github.com/kenji0x02/pecorian/pecorian.d
}
pecorian_config_base=`pecorian_config_base`
for f in `ls -1 $pecorian_config_base/*.sh`; do
  source "${f}"
done

export PECORIAN_IFS_BACKUP=$IFS

# main
pecorian_cmd() {
  # 配列に半角スペースを許す
  IFS=$'\n'

  # 1) select scope
  scope_list=()

  if [ -e "$pecorian_config_base/current_dir.sh" ]; then 
    local scope_current_dir="Current dir"
    local scope_current_dir_all_sub_dir="Current dir + all sub dir"
    scope_list=(${scope_list[@]} $scope_current_dir)
    scope_list=(${scope_list[@]} $scope_current_dir_all_sub_dir)
  fi

  if [ -e "$pecorian_config_base/favorite.sh" ]; then 
    if [ -e ~/.dir_favorite ]; then 
      local scope_favorite="Favorite"
      scope_list=(${scope_list[@]} $scope_favorite)
    fi
  fi

  if [ -e "$pecorian_config_base/git_repository.sh" ]; then 
    if type "ghq" > /dev/null 2>&1; then
      local scope_git_rep="Git repository(ghq)"
      scope_list=(${scope_list[@]} $scope_git_rep)
    fi
  fi

  if [ -e "$pecorian_config_base/process.sh" ]; then 
    local scope_process="Process"
    scope_list=(${scope_list[@]} $scope_process)
  fi

  if [ -e "$pecorian_config_base/path.sh" ]; then 
    local scope_path="Path"
    scope_list=(${scope_list[@]} $scope_path)
  fi

  if [ -e "$pecorian_config_base/trush.sh" ]; then 
    if pecorian_is_windows_os || pecorian_is_mac_os; then 
      local scope_trush="Trush"
      scope_list=(${scope_list[@]} $scope_trush)
    fi
  fi

  if [ -e "$pecorian_config_base/docker_container.sh" ]; then 
    # dockerコマンドが存在した場合のみ表示
    # whichコマンドで探すよりも組込みコマンドのtypeの方が速いらしい
    # http://qiita.com/kawaz/items/1b61ee2dd4d1acc7cc94
    if type "docker" > /dev/null 2>&1; then
      # need to start docker for windows
      if pecorian_is_windows_os; then
        if [ "$DOCKER_HOST" != "" ]; then
          if [ -n "$(docker ps -a --format {{.ID}})" ]; then
            local scope_docker_container="Docker a container"
            scope_list=(${scope_list[@]} $scope_docker_container)
          fi
        fi
      else
        if [ -n "$(docker ps -a --format {{.ID}})" ]; then
          local scope_docker_container="Docker a container"
          scope_list=(${scope_list[@]} $scope_docker_container)
        fi
      fi
    fi
  fi

  if [ -e "$pecorian_config_base/docker.sh" ]; then 
    if type "docker" > /dev/null 2>&1; then
      if pecorian_is_windows_os; then
        if [ "$DOCKER_HOST" != "" ]; then
          local scope_docker="Docker containers/images"
          scope_list=(${scope_list[@]} $scope_docker)
        fi
      else
        local scope_docker="Docker containers/images"
        scope_list=(${scope_list[@]} $scope_docker)
      fi
    fi
  fi

  if [ -e "$pecorian_config_base/conda.sh" ]; then 
    if type "conda" > /dev/null 2>&1; then
      local scope_conda="Python packages(conda)"
      scope_list=(${scope_list[@]} $scope_conda)
    fi
  fi

  local scope=$( for s in ${scope_list[@]}; do echo $s; done | pip_peco target )
  [ -z "$scope" ] && pecorian_abort

  # create command for each scope
  case $scope in
    $scope_current_dir)
      pecorian_current_dir_cmd 1
      ;;
    $scope_current_dir_all_sub_dir)
      pecorian_current_dir_cmd all
      ;;
    $scope_favorite)
      pecorian_favorite_cmd
      ;;
    $scope_git_rep)
      pecorian_git_repository_cmd
      ;;
    $scope_process)
      pecorian_process_cmd
      ;;
    $scope_path)
      pecorian_path_cmd
      ;;
    $scope_trush)
      pecorian_trush_cmd
      ;;
    $scope_docker_container)
      pecorian_docker_container_cmd
      ;;
    $scope_docker)
      pecorian_docker_cmd
      ;;
    $scope_conda)
      pecorian_conda_cmd
      ;;
    *)
      exit 1
  esac

  IFS=$PECORIAN_IFS_BACKUP

  return
}
