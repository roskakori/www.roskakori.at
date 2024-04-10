# www.roskakori.at

This is the [Lektor](https://www.getlektor.com/) source code for the homepage of
Thomas Aglassinger.

## Set up

Create the [poetry](https://python-poetry.org/) environment:

```bash
cd $WORKSPACE/www.roskakori.at
sh scripts/setup_project.sh
```

Run server that automatically rebuild changed files and open browser:

```bash
sh scripts/run_server.sh
```

## Deployment

Ideally you could just run:

```bash
sh scripts/deploy.sh  # DOES NOT WORK
```

Because this does not seem to work, use a 2 step process:

1. Run
   ```bash
   sh scripts/build_to_tmp,sh
   ```
2. Manually FTP the files in `/tmp/roskakori.at`.
