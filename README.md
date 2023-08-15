# Group based map config

### The way to separate config per group not a map.

# Install
1. Download this repo as zip
2. Install to proper folder
3. Done

# Customize

### 1. Add group in config
You can simply add groups for adding line in addons/sourcemod/configs/GroupBasedMapConfig/gbmc-config.txt
```
"groups"
{
    "multigames"{}
    "course"{}
    // Add like this below
    "justAddGroupHere"{}
}
```
### 2. Create map list file
Create map list file named `<groupname>_maps.txt` (e.g. justAddGroupHere_maps.txt)

Then write map name in txt file (Don't need extension!)
```
mg_yourstory
mg_azure
```
### 3. Create group cfg
Create `<groupname>.cfg` in cfg/sourcemod/GroupBasedMapConfig/

Then write same like server.cfg

### 4. Reload config and reload map
Use `gbmc_reload` to reload everything. but need reload map  to take effect.