<div align='center'>

eaws - easy aws cli
==================================================

```

__/\\\\\\\\\\\\\\\_____/\\\\\\\\\_____/\\\______________/\\\_____/\\\\\\\\\\\___        
 _\/\\\///////////____/\\\\\\\\\\\\\__\/\\\_____________\/\\\___/\\\/////////\\\_       
  _\/\\\______________/\\\/////////\\\_\/\\\_____________\/\\\__\//\\\______\///__      
   _\/\\\\\\\\\\\_____\/\\\_______\/\\\_\//\\\____/\\\____/\\\____\////\\\_________     
    _\/\\\///////______\/\\\\\\\\\\\\\\\__\//\\\__/\\\\\__/\\\________\////\\\______    
     _\/\\\_____________\/\\\/////////\\\___\//\\\/\\\/\\\/\\\____________\////\\\___   
      _\/\\\_____________\/\\\_______\/\\\____\//\\\\\\//\\\\\______/\\\______\//\\\__  
       _\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_____\//\\\__\//\\\______\///\\\\\\\\\\\/___ 
        _\///////////////__\///________\///_______\///____\///_________\///////////_____
                                                                                  
```

</div>

---

EAWS was developed using the [Bashly Command Line Framework][bashly].


Prerequisites
--------------------------------------------------

- jq (`brew install js` on mac).
- aws (`brew install awscli` on mac) 
- session-manager-plugin (`brew install --cask session-manager-plugin` on mac) 
- fzf (`brew install fzf` on mac) 
- granted (`brew tap common-fate/granted && brew install granted` on mac) 



Usage
--------------------------------------------------

```
$ eaws -h                                   
eaws - Simple aws cli

Usage:
  eaws [OPTIONS] COMMAND
  eaws [COMMAND] --help | -h
  eaws --version

Commands:
  logs        Show logs from cloudwatch
  container   Helper command to manage ecs containers

Options:
  --help, -h
    Show this help

  --version
    Show version number

  --verbose, -v
    Print everything

  --profile, -p PROFILE


Environment Variables:
  AWS_PROFILE
    Set your API key

```
