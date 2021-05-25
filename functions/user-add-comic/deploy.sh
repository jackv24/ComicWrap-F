#!/bin/sh
echo 'Enter function ID:'

read functionId

appwrite functions createTag \
    --functionId=$functionId \
    --command="deno run --allow-env --allow-net main.ts" \
    --code="."