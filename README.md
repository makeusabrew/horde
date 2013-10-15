# horde

Unleash hordes of [zombies](https://github.com/assaf/zombie) to tear your [test
suite](http://visionmedia.github.io/mocha/) to shreds in record time.

## About

Horde is designed to solve a fairly specific problem: speeding up very long
running integration test suites which use the
[Mocha](http://visionmedia.github.io/mocha/) test framework to run the
[Zombie.js](http://zombie.labnotes.org/) headless browser against
a fairly typical LAMP powered website.

It assumes that the bottleneck in such a scenario is largely the DB layer;
both in terms of priming it with test data and in terms of contention
over it - parallelism is hard when multiple test suites are all squabbling
over the same test database.

## How?

Each test suite run is in its own [docker container](http://www.docker.io/)
which not only isolates each database instance but also the entire LAMP
server itself. As an added bonus, running multiple processes will make
better use of multi-core processors than a single NodeJS instance. The
master horde process stitches the results of each docker's
test results into a JUnit compatible XML file making horde perfect for use
in continuous integration environments.

## Why?

Because running large DB-bound suites in parallel - in *my* experience at
least - can yield **huge** speed increases. A sample suite of X tests
which previously took 9 minutes 20 seconds to run now runs in 1 minute
26 seconds - roughly **85%** faster.

## Usage

Coming soon.
