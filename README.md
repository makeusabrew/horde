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

## Usage

Coming soon.

## Sample output
```
$ ./bin/horde /var/www/nick/myproject makeusabrew/horde output.xml 8
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
