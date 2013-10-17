# horde

Unleash hordes of [zombies](https://github.com/assaf/zombie) to tear your [test
suite](http://visionmedia.github.io/mocha/) to shreds in record time!

## What?

Horde is designed to solve a fairly specific problem: speeding up very long
running integration test suites which use the
[Mocha](http://visionmedia.github.io/mocha/) test framework to run the
[Zombie.js](http://zombie.labnotes.org/) headless browser against
a fairly typical LAMP powered website.

It assumes that the bottleneck in such a scenario is largely the DB layer;
both in terms of priming it with test data and in terms of contention
over it: parallelism is hard when multiple test suites are all squabbling
over the same test database.

## How?

By splitting your test suite up into multiple smaller ones and running them
in parallel inside individual [docker containers](http://www.docker.io/). This
not only completely isolates each database instance but *also* the entire LAMP
server itself. The
master horde process stitches the results of each container's
test results into a JUnit compatible XML file making horde perfect for use
in continuous integration environments. As an added bonus, running multiple
processes will make much better use of multi-core processors than a single
NodeJS instance.

## Why?

Because running large integration suites in parallel - in *my* experience at
least - can yield **huge** speed increases. A sample suite of 1,062 tests
which previously took 9 minutes 20 seconds to run now executes in 1 minute
21 seconds - over **85%** faster.

## Getting started

### Docker

* install [docker](http://www.docker.io/gettingstarted/#h_installation) if you haven't already
* add your user to the `docker` group so you don't have to keep running every docker command with `sudo`

### Horde

* pull down the horde docker image: `docker pull makeusabrew/horde`
* clone this repository
* run `npm install`
* run `npm install -g coffee-script` if you don't already have it


## Configuration (LAMP environment setup)

In order to make the `makeusabrew/horde` docker image reusable you'll need
to give it a hand by creating a couple of configuration files it'll look for
upon initialisation: one for MySQL and one for Apache. For the time being
these configuration files *must* live in the same directory *and* match specific
filenames so that the horde image can find them. This directory can live anywhere
but since it'll probably be specific to the project you're testing it's advisable
to keep it there, perhaps under a `horde/` directory.

### default.conf

This is the apache configuration file needed in order to run your site. At run time
it'll be linked as the *only* file in `/etc/apache2/sites-enabled/` and as
such will act as the container's default (and only) host. In my usage so far this
has amounted to a single `VirtualHost` entry adapted from the site I'm testing.

### schema.sql (optional)

If present, this file will be run once upon container initialisation. It allows you
to initialise the test database with a clean schema against which your test
fixtures can be run.

### Assumptions

Since our containers spawn a completely isolated LAMP stack, they make a couple of
key assumptions:

* the source directory you provide when running the horde script (discussed later)
  will be mounted as `/var/www` (e.g. Apache's default document root)
* the schema you provide will be run against `horde_test` as `root` with **no password**
* we don't inject any `/etc/hosts` entries into the container, but as your site is
  the only one available it'll respond to requests (from within the container) to
  `http://localhost`

These assumptions mean that:

* your `default.conf` file should assume specify any relevant directives with `/var/www`
  as the root. For example, if you have a 'public' folder which is typically your
  document root, instead of `DocumentRoot /path/to/myproject/public`, use `/var/www/public`
* your site's test configuration should point to a database named `horde_test`, accessed
  by user `root` with no password (or a blank password)
* if your site generates absolute URLs, the host name in test mode should be `localhost`

## Unleashing

```
$ ./bin/horde --help

  Usage: horde [options]

  Options:

    -h, --help           output usage information
    -p, --procs <n>      Number of containers to spawn [4]
    -o, --output [file]  XML file to write JUnit results to
    -s, --source [dir]   Source directory to mount
    -c, --config [dir]   Configuration directory to mount
    -i, --image [image]  Docker image to use [makeusabrew/horde]
```

The two required parameters are `--source` and `--config`:

### --source

This **must** be an absolute path to a project which itself contains
a `test/` directory, i.e. one should be able to run `mocha` from within
`--source` and expect it to run and find some appropriate tests.

### --config

This **must** be an absolute path to a directory which contains the
aforementioned `default.conf` apache configuration file. If it
contains a `schema.sql` this will be run against the MySQL server
within each container upon initialisation.

## Sample output

```
Attempting to fetch optimum suite distribution, please wait...
Best average deviation of 6 (total: 44)

Spawning docker container [1] with approx. 133 tests in 9 files
Spawning docker container [2] with approx. 140 tests in 9 files
Spawning docker container [3] with approx. 135 tests in 9 files
Spawning docker container [4] with approx. 122 tests in 9 files
Spawning docker container [5] with approx. 139 tests in 9 files
Spawning docker container [6] with approx. 141 tests in 9 files
Spawning docker container [7] with approx. 145 tests in 9 files
Spawning docker container [8] with approx. 143 tests in 9 files

Starting mocha test suite [2] with 127 tests (127)
Starting mocha test suite [5] with 139 tests (266)
Starting mocha test suite [8] with 142 tests (408)
Starting mocha test suite [1] with 124 tests (532)
Starting mocha test suite [6] with 137 tests (669)
Starting mocha test suite [4] with 121 tests (790)
Starting mocha test suite [3] with 135 tests (925)
Starting mocha test suite [7] with 137 tests (1062)

.................................................. (~5%)
.................................................. (~9%)
.................................................. (~14%)
.................................................. (~19%)
.................................................. (~23%)
.................................................. (~28%)
.................................................. (~33%)
.................................................. (~38%)
.................................................. (~42%)
.................................................. (~47%)
.................................................. (~52%)
.................................................. (~56%)
.................................................. (~61%)
.................................................. (~66%)
.................................................. (~71%)
.................................................. (~75%)
.................................................. (~80%)
.................................................. (~85%)
...✓.............✓....✓........................... (~89%) (containers: 8, 4, 5)
...........................✓...................... (~94%) (containers: 3)
.✓...............✓...........✓.................... (~99%) (containers: 6, 1, 2)
...................✓                               (100%) (containers: 7)


--------------------------------------------------

8 test suites run in a total of 87 seconds, 84% quicker than in serial (532)

Writing test results to output.xml
Exiting with overall status 0
```
