#!/bin/bash

# Define the base URLs for server-a and server-b
current_server="http://localhost:8080/db/"
new_server="http://localhost:8081/db/"

# Define an array of pages to check
pages=("artifact" "beat" "beep" "dome" "geo" "kaching" "minion" "os3" "os3t" "sanitizer" "telegram" "vortex" "whirl" )

# Function to extract the value of "collections" from a given URL
get_objects_count() {
    local url=$1
    local auth=$2
    local collections_value=$(curl -s $auth "$url" | grep -A1 -E 'Objects #' | grep -v 'Objects' | grep -Eo '[0-9]+')
    echo "$collections_value"
}

get_index_count() {
    local url=$1
    local auth=$2
    local collections_value=$(curl -s $auth "$url" | grep -A1 -E 'Indexes #' | grep -v 'Indexes' | grep -Eo '[0-9]+')
    echo "$collections_value"
}

# Loop through each page and compare collections values
for page in "${pages[@]}"; do
    server_a_url="$current_server$page"
    server_b_url="$new_server$page"

    objects_current=$(get_objects_count "$server_a_url")
    objects_new=$(get_objects_count "$server_b_url" "-u admin:pass")

    if [ "$objects_current" = "$objects_new" ]; then
        echo "The objects count for $page on current and new are the same: $objects_current"
    else
        echo "!!! The objects count for $page on current ($objects_current) and new ($objects_new) are different."
    fi


    indices_current=$(get_index_count "$server_a_url")
    indices_new=$(get_index_count "$server_b_url" "-u admin:pass")

    if [ "$indices_current" = "$indices_new" ]; then
        echo "The index count for $page on current and new are the same: $indices_current"
    else
        echo "!!! The index count for $page on current ($indices_current) and new ($indices_new) are different."
    fi
done
