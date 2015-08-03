# todo-manager package

Manage TODOs, NOTEs, etc. from inside Atom.

**Note: This package requires [bottom-dock](https://atom.io/packages/bottom-dock)**

##### Commands
* ctrl-k ctrl-t: toggles panel
* ctrl-k ctrl-r: refreshes window
* ctrl-k ctrl-c: closes window
* ctrl-k ctrl-m: adds todo pane

![image](https://cloud.githubusercontent.com/assets/9221137/9021425/3961b8d8-37f6-11e5-95e4-e283b9802dea.png)


##### Config
To add additional strings to check for extend the config.cson file, which can be found at File > Open Your Config.

Below are the default settings:

````coffee
"todo-manager":
  regexes: [
    {
      regexName: "TODO"
      regexString: "/\\b@?TODO:?\\s(.+$)/g"
    }
    {
      regexName: "NOTE"
      regexString: "/\\b@?NOTE:?\\s(.+$)/g"
  ]
````
Note: Adding too many regexes can cause performance problems.


##### Future Plans
* Improve regexMatcherUtil to take array of regexes so multiple scans aren't necessary.
