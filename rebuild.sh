#!/bin/bash

echo "building..."
toolforge build start https://github.com/abartov/erex_yomi
echo "deleting existing job"
toolforge jobs delete erex-yomi
echo "scheduling job"
toolforge jobs run --schedule '0 19 */2 * *' --mount=all --command=run-cron --image=tool-erex-yomi/tool-erex-yomi:latest
