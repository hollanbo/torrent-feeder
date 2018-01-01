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
    elif [ "$entity" == "/item" ]; then
      is_item=false

      processItem "${data[@]}"
    fi

    if [ is_item ]; then
      case "$entity" in
        "tv:raw_title")
            data[0]="$content"
            ;;

        "link")
            data[1]="$content"
            ;;

        "tv:info_hash")
            data[2]="$content"
            ;;
        "tv:show_name")
            data[3]="$content"
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

  grep -Fq "${data[2]}" processed
  hash_found=$?

  if [ $hash_found -gt 0 ]
  then
      prepareRequest "${data[@]}"
      echo ${data[2]} >> processed
  fi

}

function prepareRequest () {
  data=$1
  ep_number=$(echo "${data[0]}" | sed -n 's/.*\([sS][0-9][0-9][eE][0-9][0-9]*\).*/\1/p')
  season=${ep_number:1:2}

  json="{
    \"method\": \"torrent-add\",
    \"arguments\": {
      \"filename\": \"${data[1]}\",
      \"paused\": \"false\"
    }
  }"

  sendRequest "$json"

}

function sendRequest () {
  json=$1

  response=$(curl "$TORRENT_CLIENT_HOST" -i -H "Content-Type: application/json" -H "X-Transmission-Session-Id: $csrf" --data-raw "$json")


  curl_exit_code=$?
  if [ $curl_exit_code -gt 0 ]
  then
    exit 1
  fi

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

      # Some bullshit invisible character at
      # the end of the string has kept me up for a while
      csrf=${csrf//[^[:alnum:]]/}
      sendRequest "$json"
      return
    fi
  done <<< "$response"
}

init
