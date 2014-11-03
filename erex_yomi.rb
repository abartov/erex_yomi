#!ruby 
#
# Erex Yomi e-mails a featured article, picture, and Today in History from the Hebrew Wikipedia to subscribers, via a mailing list
# 
# Author: Asaf Bartov
# Source: https://github.com/abartov/erex_yomi
# 
# This code is in the public domain.  Where not allowed, it is released under the Creative Commons Zero License (CC0).
#
# you will need to install the 'mediawiki-gateway' and 'actionmailer' gems.

require "rubygems"
require 'bundler/setup'
require 'date'
require 'uri'
require 'media_wiki'
require 'action_mailer'

HTML_PROLOGUE = "<html lang=\"he\" dir=\"rtl\"><head><meta charset=\"UTF-8\" /><body dir=\"rtl\" align=\"right\">"
HTML_EPILOGUE = "</body></html>"
HEBMONTHS = [nil, 'בינואר', 'בפברואר', 'במרץ', 'באפריל', 'במאי', 'ביוני', 'ביולי', 'באוגוסט', 'בספטמבר', 'באוקטובר', 'בנובמבר', 'בדצמבר']

ABOUT_TEXT = <<endtext
<p>מתנדבי ויקיפדיה מתכבדים להגיש לך ערך מומלץ, תמונה מומלצת, ומקבץ אירועים מן הלוח הלועזי והעברי שאירעו בתאריך זה. אנו מזמינים אותך <a href="https://he.wikipedia.org/wiki/%D7%95%D7%99%D7%A7%D7%99%D7%A4%D7%93%D7%99%D7%94:%D7%91%D7%A8%D7%95%D7%9B%D7%99%D7%9D_%D7%94%D7%91%D7%90%D7%99%D7%9D">להצטרף אלינו</a>! ולסייע בויקיפדיה על-ידי כתיבה, הגהה, מיון לקטגוריות, שיוך תמונות לערכים, יצירת איורים, ועוד.</p><br/>
endtext

ABOUT_FOOTER = <<endtext
<hr/><p>עמותת <a href="http://wikimedia.org.il/"><b>ויקימדיה ישראל</b></a> היא עמותה (מס' עמותה 580476430) הפועלת בשיתוף פעולה עם קרן ויקימדיה הבינלאומית לקידום הידע וההשכלה בישראל באמצעות איסופם, יצירתם והפצתם של תכנים חופשיים ובאמצעות ייזום פרויקטים להקלת הגישה למאגרי ידע.</p>
endtext

REXML::Document.entity_expansion_text_limit = 200000

class Mailer < ActionMailer::Base
  def daily_email(body)
    mail( :to => "daily-article-he@lists.wikimedia.org", :from => "dailyarticle@wikimedia.org.il", :subject => " תוכן מומלץ יומי מויקיפדיה - "+heb_date) do |format|
      format.html { render text: body }
    end
  end
end

def fixlinks(str)
  return str.gsub('href="/','href="http://he.wikipedia.org/').gsub('//upload.wiki','http://upload.wiki')
end

def prepare_article_part(mw)
# this one is useful if a single fixed-name template renders the daily recommended article correctly.  This doesn't seem to work well with the API; for some reason, I'm getting the same recommended article every time.
  h = mw.render('תבנית:ערך מומלץ '+heb_date)
  m = /לערך המלא/.match h
  s = m.pre_match[m.pre_match.rindex('href="/wiki/')+12..-1]
  raw_name = s[0..s.index('"')-1]
  article_link = "https://he.wikipedia.org/wiki/#{raw_name}"
  article_title = URI.unescape(raw_name).gsub('_', ' ')
  print "- Title: #{article_title} - "
  h = mw.render(article_title)
  # grab everything before the TOC
  m = /(<p>.*<\/p>).*<table id=\"toc\" class=\"toc\">/m.match(h)
  if m.nil?
    m = /(<p>.*<\/p>).*<div id=\"toc\" class=\"toc\">/m.match(h)
  end
  if m.nil?
    puts "ERROR finding intro part!  Aborting..."
    exit
  end
  return '<div dir="rtl" align="right"><h1>ערך מומלץ: '+'<a href="'+article_link+'">'+article_title+'</a></h1>'+fixlinks(m[1])+'</div>'
end

def prepare_today_in_history(mw)
  h = mw.render('תבנית:היום בהיסטוריה '+heb_date(false))
  m = /<ul>.*<\/ul>/m.match(h)
  return '<div dir="rtl" align="right"><h1>היום בהיסטוריה</h1>'+fixlinks(m.to_s)+'</div>'
end
def prepare_today_in_hebcal(mw)
  h = mw.render('תבנית:אירועים בלוח העברי')
  m = /<ul>.*<\/ul>/m.match(h)
  return '<div dir="rtl" align="right"><h1>אירועים בלוח העברי</h1>'+fixlinks(m.to_s)+'</div>'
end
def heb_date(with_year = true)
  d = Date.today
  return "#{d.day} #{HEBMONTHS[d.month]}" + (with_year ? " #{d.year}" : '')
end
def prepare_daily_quotation(mw)
  h = mw.render('תבנית:ציטוט יומי '+heb_date)
  m = /<table cellpadding=\"2\" class=\"hebrewQuotation\".*/m.match(h) # skip all the calendar nav stuff, ridiculously hard-coded
  #debugger
  if m.nil?
    puts "ERROR finding quotation part! Aborting..."
    return ''
  end
  return '<div dir="rtl" align="right"><h1>ציטוט יומי</h1>'+fixlinks(m.to_s)+'</div>'
end
def prepare_daily_picture(mw)
  h = mw.render('תבנית:תמונה מומלצת '+heb_date)
  m = /<\/table>\s*(<p>.*<\/p>)/m.match h
  if m.nil?
    puts "ERROR finding picture part!  Aborting..."
    return ''
  end
  return '<div dir="rtl" align="right"><h1>תמונה מומלצת</h1>'+fixlinks(m[1].to_s)+'</div>'
end

# main
puts "Hi!"
mw = MediaWiki::Gateway.new('http://he.wikipedia.org/w/api.php')
body = HTML_PROLOGUE + ABOUT_TEXT
print "Preparing featured article... "
body += prepare_article_part(mw)
print "done!\nPreparing Daily Quotation... "
body += prepare_daily_quotation(mw)
print "done!\nPreparing Today in History... "
body += prepare_today_in_history(mw)
print "done!\nPreparing Today in Hebrew Calendar... "
body += prepare_today_in_hebcal(mw)
print "done!\nPreparing Recommended Picture... "
body += prepare_daily_picture(mw)
body += ABOUT_FOOTER + HTML_EPILOGUE
print "done!\nSending... "

Mailer.delivery_method = :sendmail
Mailer.sendmail_settings = {:arguments => "-i" }
Mailer.logger = Logger.new(STDOUT)
themail = Mailer.daily_email(body)
themail.deliver
#puts "TEMPORARILY NOT SENDING" #themail.deliver
puts "done!"
File.open('last_sent.html', 'w') {|f| f.write(body)}

puts "Bye!"

