# Pecorian

![Pecorian Logo](img/pecorian.png)

Shell script tool to use `peco` without keymap or alias.
For all `peco` lovers.

## Demo

i.e. if you select **scope**, **target**, and **action** via `peco`, then the command is created automaically. The scenario is predefined by shell script.

## Example

|Want to|Scope|Target|Action|Command ex.|
|:--|:--|:--|:--|
|select file and vi|Current dir|_file_|vi|vi _file_|
|cd after selecting repository via `ghq`|Git repository(ghq)|_repository_|cd|cd _repository_|
|kill running process|Process|_PID_|kill|kill _PID_|
|show log on docker-compose|Docker containers/images|container managed by Compose|logs|docker-compose logs -tf|

Many other commands can be created.

## Other Features

* Support bash and zsh
* Multi platform for some command
* Special keymap for frequency used scenario
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

[MIT](https://github.com/kenji0x02/pecorian/blob/master/LICENCE)

## Author

[kenji0x02](https://github.com/kenji0x02)
