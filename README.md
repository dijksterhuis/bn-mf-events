# README

## IMPORTANT LICENSING INFORMATION

We're still finalising the license under which this code can be modified and redistributed. 
Until the new license is published, you can modify this work under the original license within this repository, further to the conditions stated here: https://community.sogpf.com/d/198-modifying-mike-force.

## Usage (Curation team)

1. Go to the [Releases](https://github.com/dijksterhuis/bn-mf-events/releases) tab (right hand side of the screen) and find the release with the "Latest" tag on it.
2. Download the `.zip` file with a name tat starts with `AllMPMissions_` 
3. Copy the Downloaded Zip file to your Arma 3 profile folder.
4. Extract allthe contents of your Zip file. You should end up with 4 folders for each map, prefixed by `bn_mikeforce_events`
5. Start editing your mission!


## Maintenance (Development Team)

Unfortuantely GitHub does not allow for multiple forks to be created for the same upstream repo in the same account.

This means that [upstream](https://github.com/Bro-Nation/Mike-Force) changes have to be integrated locally and pushed here.

In a bash shell

```bash
git clone https://github.com/dijksterhuis/bn-mf-events ./bn-mf-events
cd ./bn-mf-events/
git remote add upstream https://github.com/Bro-Nation/Mike-Force
git fetch -a upstream
git checkout -b some-branch-name-for-integrating-upstream-changes
git merge upstream/development
git push -u origin some-branch-name-for-integrating-upstream-changes
```

This creates a new branch in the [Events Edition GitHub repo](https://github.com/dijksterhuis/bn-mf-events/).

Now you can create a pull request on that branch within the same repository. 

Then someone (probably @dijksterhuis) can (maybe) merge it.