#!/bin/bash
#
# Import config file
source config.sh

# Global csrf var
csrf=

# Initialize feed sync
function init() {
  getXml
}

function getXml() {
  count=0
  while [ "x${FEEDS[count]}" != "x" ]
  do
    curl ${FEEDS[count]} -o feed.xml
    parseXmlFeed
    count=$(( $count + 1 ))
  done
}

function parseXmlFeed() {
  is_item=false
  while read_dom; do
    if [ "$entity" == "item" ]; then
      is_item=true
      unset  data
      declare -A data
    elif [ "$entity" == "/item" ]; then
      is_item=false
      processItem $data
    fi

    if [ is_item ]; then
      case "$entity" in
        "tv:raw_title")
            data[title]=$content
            ;;

        "link")
            data["link"]=$content
            ;;

        "tv:info_hash")
            data["hash"]=$content
            ;;
        "tv:show_name")
            data[show_name]=$content
            ;;
      esac
    fi
  done < feed.xml

}

function read_dom () {
    local IFS=\>
    read -d \< entity content
}

function processItem () {
  data=$1

  grep -Fxq "${data[hash]}" processed
  hash_found=$?

  if [ $hash_found -gt 0 ]
  then
      prepareRequest $data
      echo ${data[hash]} >> processed
  fi

}

function prepareRequest () {
  data=$1
  ep_number=$(echo "${data[title]}" | sed -n 's/.*\([sS][0-9][0-9][eE][0-9][0-9]*\).*/\1/p')
  season=${ep_number:1:2}

  json="{
    \"method\": \"torrent-add\",
    \"arguments\": {
      \"filename\": \"${data[link]}\",
      \"paused\": \"false\"
    }
  }"

  sendRequest "$json"

}

function sendRequest () {
  json=$1

  response=$(curl "http://192.168.1.77:9091/transmission/rpc" -i -H "Content-Type: application/json" -H "X-Transmission-Session-Id: mr4igRej1QJzftS63DZ3dfvPZCrSlYt1Dl4N5qlHlQQeHNSX" --data-raw "$json")

  grep -Fq "HTTP/1.1 409 Conflict" <<< "$response"
  csrf_error=$?

  if [ $csrf_error -eq 0 ]
  then
      updateCsrf "$json" "$response"
  fi
}

function updateCsrf () {
  json=$1
  response=$2
  needle="X-Transmission-Session-Id: "

  while IFS= read -r line
  do
    if [[ $line == *"X-Transmission-Session-Id"* ]]
    then
      csrf=${line##$needle}
      echo $csrf
      sendRequest json
      return
    fi
  done <<< "$response"
}

init
