#!/bin/bash
coffee /run.coffee --reporter json-stream test/faqs.coffee
echo "[zombie] done $?"
