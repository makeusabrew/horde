module.exports =
class XUnitReporter
  formatResults: (results, totalStats) ->
    buffer = []
    buffer.push '<testsuite name="Test Results" tests="'+totalStats.tests+'" failures="'+totalStats.failures+'" errors="0" skip="'+totalStats.pending+'" timestamp="'+totalStats.start.toString()+'" time="'+totalStats.secs+'">'

    for test in results
      details = test.details

      if details.fullTitle
        idx = details.fullTitle.indexOf(details.title)
        if idx isnt -1
          fullTitle = details.fullTitle.substr(0, idx-1)
        else
          fullTitle = details.fullTitle
      else
        fullTitle = ""

      if details.title
        title = details.title
      else
        title = ""

      title = title.replace /"/g, ""
      title = title.replace /&/g, "&amp;"

      fullTitle = fullTitle.replace /"/g, ""
      fullTitle = fullTitle.replace /&/g, "&amp;"

      switch test.status
        when "pass"
          buffer.push '<testcase classname="'+fullTitle+'" name="'+title+'" time="'+(details.duration / 1000)+'"/>'
        when "fail"
          buffer.push '<testcase classname="'+fullTitle+'" name="'+title+'" time="'+(details.duration / 1000)+'">'
          buffer.push '<failure classname="'+fullTitle+'" name="'+title+'" time="'+(details.duration / 1000)+'">Test Failed</failure>'
          buffer.push '</testcase>'

    buffer.push '</testsuite>'

    return buffer.join "\n"
