# www.roskakori.at

This is the [Nikola](https://getnikola.com/) source code for the homepage of
Thomas Aglassinger.

## Set up

Create virtual environment:

```bash
cd $WORKSPACE/www.roskakori.at
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

# Build

Activate environment:

```bash
cd $WORKSPACE/www.roskakori.at
source venv/bin/activate
```

Run server that automatically rebuild changed files and open browser:

```bash
nikola auto --browser
```
