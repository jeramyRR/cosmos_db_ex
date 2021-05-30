# Local_Dev

This folder is a place for you to put any scripts or source files with secrets or anything that you don't want controlled in this repo.  The whole folder, except for this README will be ignored via .gitignore.

I personally place a setup_env.sh script here to load Environment Variables, like my Cosmos DB Primary Key, while testing.

Before starting the project with `iex -S mix` or `mix test` I run the following to set up my environment.

```bash
source local_dev/setup_env.sh
```

My setup_env.sh script looks like:

```bash
export COSMOS_DB_KEY="some key here"
export ANOTHER_ENV_VAR="some value here"

# Import anything from a mounted dir here.
cp -r /mnt/c/Users/username/folder_to_import /usr/local/share/folder
```