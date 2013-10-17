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
which previously took around 9 minutes 20 seconds to run now executes at best
in 1 minute 21 seconds - over **85%** faster.

## Getting started

### Docker

* install [docker](http://www.docker.io/gettingstarted/#h_installation) if you haven't already
* add your user to the `docker` group so you don't have to keep running every docker command with `sudo`
  (and since horde spawns docker sub processes, it means you don't have to run *that* with sudo either)
* pull down the horde [docker image](https://index.docker.io/u/makeusabrew/horde/): `docker pull makeusabrew/horde`

### Horde


* clone this repository
* run `npm install`
* run `npm install -g coffee-script` if you don't already have it


## Configuration (LAMP environment setup)

In order to make the `makeusabrew/horde` docker image reusable you need
to give it a hand by creating a couple of configuration files it'll look for
upon initialisation: one for MySQL and one for Apache. For the time being
these configuration files *must* live in the same directory *and* match specific
filenames so that the horde image can find them. This directory can live anywhere
but since it'll probably be specific to the project you're testing it's advisable
to keep it there under a `horde/` directory. This also helps when running
the horde script as it'll look there first for any configuration files.

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

Since our containers spawn a completely isolated LAMP stack, they make a few
key assumptions:

* the source directory you provide when running the horde script (discussed later)
  will be mounted as `/var/www` (e.g. Apache's default document root)
* the schema you provide will be run against `horde_test` as `root` with **no password**
* we don't inject any `/etc/hosts` entries into the container, but as your site is
  the only one available it'll respond to requests (from within the container) to
  `http://localhost`

These assumptions mean that:

* your `default.conf` file should specify any relevant directives with `/var/www`
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
    -c, --config [dir]   Configuration directory to mount [--source/horde]
    -i, --image [image]  Docker image to use [makeusabrew/horde]
```

### --source

**Default:** `process.cwd()`

An absolute path to a project which itself contains
a `test/` directory, i.e. one should be able to run `mocha` from within
`--source` and expect it to run and find some appropriate tests. This
directory will be mounted within each container as `/var/www`.


### --config

**Default:** `horde/` sub directory of `--source` option

An absolute path to a directory containing
the aforementioned `default.conf` apache configuration file. If it
contains a `schema.sql` this will be run against the MySQL server
within each container upon initialisation. This directory can live
anywhere but since it'll probably be specific to the project you're
testing it's advisable to keep it there, hence why the `horde/` sub
directory is checked first.


#### --procs

**Default:** 4

This controls how many docker containers to spawn and is limited only
by your host machine and the complexity of your test suite. Experiment!
My sample suite seems to work well with up to 20 containers on a Quad Core,
16Gb Linux machine, but any more and tests start failing unpredictably.

#### --output

**Default:** N/A

If present this controls where the combined results of all test suites
will be written to in JUnit compatible (e.g. CI friendly) XML.

#### --image

**Default:** makeusabrew/horde

If you've built your own custom horde image you can pass it here.

## Sample output

Please see [this showterm recording](http://showterm.io/55b46e947066d1dcf6b51) for
a real life test run against the 9½ minute suite referenced in this readme.
