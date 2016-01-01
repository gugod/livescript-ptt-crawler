
fs = require("fs")
walkdir = require("walkdir")
cheerio = require('cheerio')

convert-articles-html = (input-html) ->
  doc = {"body": "", "meta": [], "push": []}
  $ = cheerio.load input-html
  $(".article-metaline").each (i,el) ->
    doc["meta"].push([
        $(el).find(".article-meta-tag").text(),
        $(el).find(".article-meta-value").text()
    ])
    $(el).remove()

  $("div.push").each (i, el) ->
    doc["push"].push({
      "tag": $(el).find(".push-tag").text(),
      "userid": $(el).find(".push-userid").text(),
      "content": $(el).find(".push-content").text(),
      "ipdatetime": $(el).find(".push-ipdatetime").text()
    })
    $(el).remove()

  doc["body"] = $('#main-content').text()

  return JSON.stringify(doc)

process-one = (input-path, output-path) ->
  html = fs.readFileSync(input-path)
  json-text = convert-articles-html(html)
  fs.writeFileSync(output-path, json-text)
  console.log "==> #{output-path}"

if process.argv.length != 3
  console.log "Cannot do it"
  process.exit(1); 

input_dir = process.argv[2]

walkdir.sync input_dir, (path, stat) ->
  if path.match /\.html$/
    output-path = path.replace(/\.html$/, ".json")
    process-one path, output-path
