"use strict";

const https = require('https'),
      cheerio = require('cheerio'),
      fs = require('fs'),
      ptt_url = "https://www.ptt.cc";

ptt_get = (url, cb) ->
    req = https.get url, (res) ->
      out = "";
      res.on 'data', (chunk) -> out += chunk;
      res.on 'end', -> cb(out)
    req.end()

harvest_board_indices = (board_url, board_name, cb) ->
    ptt_get board_url, (body) ->
      $ = cheerio.load(body)
      ret = []
      $("a[href^='/bbs/#{board_name}/index']").each (i, el) ->
        href = $(el).attr("href");
        if (m = href.match(/index([0-9]+)\.html/))
          ret.push { page_number: parseInt(m[1]), url: ptt_url + href }

      [ret[1],ret[0]] = [ret[0],ret[1]] if ret[0]["page_number"] > ret[1]["page_number"]

      last_page = ret.pop();
      for i from ret[0]["page_number"] + 1 til last_page["page_number"] - 1
        ret.push { page_number: i, url: "#{ptt_url}/bbs/#{board_name}/index#{i}.html" }

      ret.push(last_page)
      cb(ret)

harvest_articles = (board_index_url, board_name, cb) ->
   ptt_get board_index_url, (body) ->
     $ = cheerio.load(body);
     ret = [];
     $("a[href^='/bbs/#{board_name}/']").each (i, el) ->
         href = $(el).attr("href");
         if m = href.match(/(M.+)\.html/)
           ret.push { id: m[1], url: ptt_url + href }
     cb(ret);

download-one-and-next = (articles, i, l, board_dir) ->
  return if i >= l
  ptt_get articles[i].url, (html) ->
    fn = "#{board_dir}/#{articles[i].id}.html"
    console.log "==> #{fn}"
    fs.writeFileSync fn, html
    download-one-and-next articles, i+1, l, board_dir

download_articles = (articles, board_name, output_dir) ->
  download-one-and-next articles, 0, articles.length, "#{output_dir}/#{board_name}"

process.abort() if process.argv.length != 4;

const board_name = process.argv[2],
      output_dir = process.argv[3];

harvest_board_indices "#{ptt_url}/bbs/#{board_name}/index.html", board_name, (board_indices) ->
  for i from 0 til board_indices.length
    harvest_articles board_indices[i].url, board_name, (a) -> download_articles(a, board_name, output_dir)
