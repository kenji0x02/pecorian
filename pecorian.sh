# load pecorian sources

pecorian_config_base()
{
  local go_path=$GOPATH
  if [ "$COMSPEC" != "" ]; then
    go_path="$( cygpath $GOPATH )" # Windowsの場合はスラッシュ表記に変更
  fi
  echo $go_path/src/github.com/kenji0x02/pecorian/pecorian.d
}
pecorian_config_base=`pecorian_config_base`
for f in `ls -1 $pecorian_config_base/*.sh`; do
  source "${f}"
done

export PECORIAN_IFS_BACKUP=$IFS

pecorian_cmd() {
  # 配列に半角スペースを許す
  IFS=$'\n'

  # 1) select scope
  scope_list=()

  if [ -e "$pecorian_config_base/current_dir.sh" ]; then 
    local scope_current_dir="Current dir"
    scope_list=(${scope_list[@]} $scope_current_dir)
  fi

  if [ -e "$pecorian_config_base/current_dir_below2.sh" ]; then 
    local scope_current_dir_below2="Current dir below depth 2"
    scope_list=(${scope_list[@]} $scope_current_dir_below2)
  fi

  if [ -e "$pecorian_config_base/current_dir_below3.sh" ]; then 
    local scope_current_dir_below3="Current dir below depth 3"
    scope_list=(${scope_list[@]} $scope_current_dir_below3)
  fi

  if [ -e "$pecorian_config_base/current_dir_below_all.sh" ]; then 
    local scope_current_dir_below_all="Current dir below depth _all"
    scope_list=(${scope_list[@]} $scope_current_dir_below_all)
  fi

  if [ -e "$pecorian_config_base/favorit.sh" ]; then 
    local scope_favorite="Favorit"
    scope_list=(${scope_list[@]} $scope_favorite)
  fi

  if [ -e "$pecorian_config_base/recent.sh" ]; then 
    local scope_reecent="Recently used"
    scope_list=(${scope_list[@]} $scope_recent)
  fi

  if [ -e "$pecorian_config_base/git_repository.sh" ]; then 
    local scope_git_rep="Git repository(ghq)"
    scope_list=(${scope_list[@]} $scope_git_rep)
  fi

  if [ -e "$pecorian_config_base/process.sh" ]; then 
    local scope_git_rep="Process"
    scope_list=(${scope_list[@]} $scope_process)
  fi

  if [ -e "$pecorian_config_base/path.sh" ]; then 
    local scope_git_rep="Path"
    scope_list=(${scope_list[@]} $scope_path)
  fi

  if [ -e "$pecorian_config_base/trush.sh" ]; then 
    # WindowまたはMacでのみ表示
    if [ "$COMSPEC" != "" ] || [ `uname` = "Darwin" ]; then 
      local scope_git_rep="Trush"
      scope_list=(${scope_list[@]} $scope_trush)
    fi
  fi

  if [ -e "$pecorian_config_base/docker_container.sh" ]; then 
    # dockerコマンドが存在した場合のみ表示
    # whichコマンドで探すよりも組込みコマンドのtypeの方が速いらしい
    # http://qiita.com/kawaz/items/1b61ee2dd4d1acc7cc94
    if type "docker" > /dev/null 2>&1; then
      local scope_git_rep="Docker a container"
      scope_list=(${scope_list[@]} $scope_docker_container)
    fi
  fi

  if [ -e "$pecorian_config_base/docker.sh" ]; then 
    if type "docker" > /dev/null 2>&1; then
      local scope_git_rep="Docker containers/images"
      scope_list=(${scope_list[@]} $scope_docker)
    fi
  fi

  local scope=$( for s in ${scope_list[@]}; do echo $s; done | pip_peco target )
  [ -z "$scope" ] && pecorian_abort

  # create command for each scope
  case $scope in
    $scope_current_dir)
      pecorian_current_dir_cmd
      ;;
    $scope_current_dir_below2)
      pecorian_current_dir_below2_cmd
      ;;
    $scope_current_dir_below3)
      pecorian_current_dir_below3_cmd
      ;;
    $scope_current_dir_below_all)
      pecorian_current_dir_below_all_cmd
      ;;
    $scope_favorite)
      pecorian_favorit_cmd
      ;;
    $scope_recent)
      pecorian_recent_cmd
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
    *)
      exit 1
  esac

  IFS=$PECORIAN_IFS_BACKUP

  return
}

pip_peco()
{
  peco --prompt="$1 >" --on-cancel error
}

pecorian_abort()
{
  IFS=$PECORIAN_IFS_BACKUP
  exit 1
}

