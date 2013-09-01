#!ruby 
#
# Erex Yomi e-mails a featured article to a mailing list
# 
# Author: Asaf Bartov
# Source: https://github.com/abartov/erex_yomi
# 
# This code is in the public domain.  Where not allowed, it is released under the Creative Commons Zero License (CC0).

require "rubygems"
require 'date'
require 'uri'
require 'media_wiki'
require 'action_mailer'

HTML_PROLOGUE = "<html lang=\"he\" dir=\"rtl\"><head><meta charset=\"UTF-8\" /><body dir=\"rtl\" align=\"right\">"
HTML_EPILOGUE = "</body></html>"
HEBMONTHS = [nil, 'בינואר', 'בפברואר', 'במארס', 'באפריל', 'במאי', 'ביוני', 'ביולי', 'באוגוסט', 'בספטמבר', 'באוקטובר', 'בנובמבר', 'בדצמבר']

REXML::Document.entity_expansion_text_limit = 200000

class Mailer < ActionMailer::Base
  def daily_email(body)
    mail( :to => "daily-article-he@lists.wikimedia.org", :from => "abartov@wikimedia.org", :subject => " תוכן מומלץ יומי מויקיפדיה - "+heb_date) do |format|
      format.html { render text: body }
    end
  end
end

def fixlinks(str)
  return str.gsub('href="/','href="http://he.wikipedia.org/').gsub('//upload.wiki','http://upload.wiki')
end

def prepare_article_part(mw)
  h = mw.render('תבנית:הערך המומלץ')
  m = /לערך המלא/.match h
  s = m.pre_match[m.pre_match.rindex('href="/wiki/')+12..-1]
  raw_name = s[0..s.index('"')-1]
  article_link = "https://he.wikipedia.org/wiki/#{raw_name}"
  article_title = URI.unescape(raw_name).gsub('_', ' ')
  print "Title: #{article_title}"
  h = mw.render(article_title)
  # grab everything before the TOC
  m = /(<p>.*<\/p>).*<table id=\"toc\" class=\"toc\">/m.match(h)
  if m.nil?
    m = /(<p>.*<\/p>).*<div id=\"toc\" class=\"toc\">/m.match(h)
  end
  if m.nil?
    die "ERROR finding intro part!  Aborting..."
  end
  return '<h1>ערך מומלץ: '+'<a href="'+article_link+'">'+article_title+'</a></h1>'+fixlinks(m[1])
end

def prepare_today_in_history(mw)
  h = mw.render('תבנית:היום בהיסטוריה')
  m = /<ul>.*<\/ul>/m.match(h)
  return '<h1>היום בהיסטוריה</h1>'+fixlinks(m.to_s)
end
def prepare_today_in_hebcal(mw)
  h = mw.render('תבנית:אירועים בלוח העברי')
  m = /<ul>.*<\/ul>/m.match(h)
  return '<h1>אירועים בלוח העברי</h1>'+fixlinks(m.to_s)
end
def heb_date
  d = Date.today
  return "#{d.day} #{HEBMONTHS[d.month]} #{d.year}" 
end

def prepare_daily_picture(mw)
  h = mw.render('תבנית:תמונה מומלצת '+heb_date)
  m = /<\/table>\s*(<p>.*<\/p>)/m.match h
  return '<h1>תמונה מומלצת</h1>'+fixlinks(m[1].to_s)
end

# main
puts "Hi!"
mw = MediaWiki::Gateway.new('http://he.wikipedia.org/w/api.php')
body = HTML_PROLOGUE
body += prepare_article_part(mw)
body += prepare_today_in_history(mw)
body += prepare_today_in_hebcal(mw)
body += prepare_daily_picture(mw)

Mailer.delivery_method = :sendmail
Mailer.sendmail_settings = {:arguments => "-i" }
Mailer.logger = Logger.new(STDOUT)
themail = Mailer.daily_email(body)
themail.deliver
File.open('last_sent.html', 'w') {|f| f.write(body)}

puts "Bye!"

