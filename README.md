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
$ ./bin/horde /var/www/nick/myproject makeusabrew/horde output.xml 12
Attempting to fetch optimum suite distribution, please wait...
Best average deviation of 11 (total: 132)

Spawning docker container [1] with approx. 79 tests in 6 files
Spawning docker container [2] with approx. 112 tests in 6 files
Spawning docker container [3] with approx. 78 tests in 6 files
Spawning docker container [4] with approx. 80 tests in 6 files
Spawning docker container [5] with approx. 102 tests in 6 files
Spawning docker container [6] with approx. 94 tests in 6 files
Spawning docker container [7] with approx. 89 tests in 6 files
Spawning docker container [8] with approx. 123 tests in 6 files
Spawning docker container [9] with approx. 89 tests in 6 files
Spawning docker container [10] with approx. 84 tests in 6 files
Spawning docker container [11] with approx. 81 tests in 6 files
Spawning docker container [12] with approx. 87 tests in 6 files

Starting mocha test suite [1] with 75 tests (75)
Starting mocha test suite [2] with 109 tests (184)
Starting mocha test suite [3] with 77 tests (261)
Starting mocha test suite [6] with 94 tests (355)
Starting mocha test suite [5] with 98 tests (453)
Starting mocha test suite [7] with 85 tests (538)
Starting mocha test suite [11] with 81 tests (619)
Starting mocha test suite [8] with 113 tests (732)
Starting mocha test suite [10] with 81 tests (813)
Starting mocha test suite [12] with 85 tests (898)
Starting mocha test suite [4] with 77 tests (975)
Starting mocha test suite [9] with 87 tests (1062)

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
...............................................✓.. (~52%) (containers: 10)
.................................................. (~56%)
.................................................. (~61%)
.................................................. (~66%)
.................................................. (~71%)
........................................✓......✓.. (~75%) (containers: 1, 12)
......✓........................................... (~80%) (containers: 9)
.........................✓.............✓.......... (~85%) (containers: 3, 6)
.................................✓................ (~89%) (containers: 5)
.................................................. (~94%)
.......................✓..✓....................✓.. (~99%) (containers: 2, 7, 4)
..........✓............✓                           (100%) (containers: 11, 8)


--------------------------------------------------

12 test suites run in a total of 82 seconds, 88% quicker than in serial (668)

Writing test results to output.xml
Exiting with overall status 0
```

