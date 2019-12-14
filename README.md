# Pecorian

![Pecorian Logo](img/pecorian.png)

Shell script tool to use [`peco`](https://github.com/peco/peco) without keymap or alias.
For all [`peco`](https://github.com/peco/peco) lovers.

## Demo

Many commands can be generated simply by selecting three items(**scope**, **target**, and **action**) via `peco`.

For example, you can change directory to a git repository using `ghq`.

![Demo: git repository](https://qiita-image-store.s3.amazonaws.com/0/36728/fb48c604-0362-d709-2b11-1311e31e6da9.gif)

Other example, you can select a process via `peco` and kill it.

![process.gif](https://qiita-image-store.s3.amazonaws.com/0/36728/5c21ff16-5e86-7885-7b1c-3272a230fcf5.gif)

You can also use docker command (ex.docker top) to docker container

![docker.gif](https://qiita-image-store.s3.amazonaws.com/0/36728/cd7c59a1-cb61-a4d0-257b-31fc303dd39c.gif)

i.e. if you select **scope**, **target**, and **action** via `peco` according to your purpose, then the command is generated automaically. The scenario is predefined by the shell script in `pecorian.d/*.sh`.


## Example

|Purpose|Scope|Target|Action|Command ex.|
|:--|:--|:--|:--|:--|
|cd after selecting repository via `ghq`|Git repository(ghq)|_repository_|cd|cd _repository_|
|kill running process|Process|_PID_|kill|kill _PID_|
|show top on a docker container|Docker a container|_container_|top|docker top _ID_|
|show log on docker-compose|Docker containers/images|container managed by Compose|logs|docker-compose logs -tf|
|select file and vi|Current dir|_file_|vi|vi _file_|

Many other commands can be created.

## Other Features

* Support bash and zsh
* Multi platform for some commands
* Special keymap is defined for frequently used scenario
    - `Ctrl + r` : search history
    - `Ctrl + h` : search change directory
- Item list is depends on the context. For example, if docker is not installed, docker scope is not shown in the list.

## Install

### bash

```bash
$ go get github.com/kenji0x02/pecorian
$ echo 'source $GOPATH/src/github.com/kenji0x02/pecorian/.bashrc.pecorian' >> ~/.bashrc
```

### zsh

```zsh
$ go get github.com/kenji0x02/pecorian
$ echo 'source $GOPATH/src/github.com/kenji0x02/pecorian/.zshrc.pecorian' >> ~/.zshrc
```

After installation, `Ctrl + j` to start pecorian.

## Requirements

- peco>=0.4.8

## Licence

[MIT](https://github.com/kenji0x02/pecorian/blob/master/LICENSE)

## Author

[kenji0x02](https://github.com/kenji0x02)
