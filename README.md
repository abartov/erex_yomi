erex_yomi
=========

Generate and e-mail a daily selection of the Hebrew Wikipedia to a(n external) list of subscribers.

The template names are all hard-coded out of sheer laziness, but it should be trivial to adapt to other Mediawiki-based sites, and you're very welcome to do so.

It is designed to be run via toolforge jobs.  Here's a sample way to run it:


    # build it
    toolforge build start https://github.com/abartov/erex_yomi
    # schedule the cron
    toolforge jobs run \
            --schedule '0 19 */2 * *' \
            --command run-cron \
            --image tool-erex-yomi/tool-erex-yomi:latest \
            --filelog

Author
======

This is an afternoon hack by Asaf Bartov <asaf.bartov@gmail.com>
