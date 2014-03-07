erex_yomi
=========

Generate and e-mail a daily selection of the Hebrew Wikipedia to a(n external) list of subscribers.

The template names are all hard-coded out of sheer laziness, but it should be trivial to adapt to other Mediawiki-based sites, and you're very welcome to do so.

It is designed to be run via cron(1).  Here's a sample crontab line:

   0 19 */2 * * /home/abartov/.rvm/rubies/ruby-2.0.0-p247/bin/ruby /home/abartov/erex_yomi/erex_yomi.rb

Author
======

This is an afternoon hack by Asaf Bartov <asaf.bartov@gmail.com>
