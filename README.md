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

By splitting your test suite up into multiple smaller ones - each of which is
run is in its own [docker container](http://www.docker.io/) - and running them
all **in parallel**. This
not only completely isolates each database instance but *also* the entire LAMP
server itself. The
master horde process stitches the results of each container's
test results into a JUnit compatible XML file making horde perfect for use
in continuous integration environments. As an added bonus, running multiple
processes will make much better use of multi-core processors than a single
NodeJS instance.

## Why?

Because running large integration suites in parallel - in *my* experience at
least - can yield **huge** speed increases. A sample suite of 1,050 tests
which previously took 9 minutes 20 seconds to run now executes in 1 minute
26 seconds - roughly **85%** faster.

## Usage

Coming soon.
