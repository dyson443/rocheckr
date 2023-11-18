#!/bin/bash

if [[ $1 == "-h" ]]; then
    echo "Usage: rocheckr [START_ID] [END_ID]"
    echo
    echo "Description:"
    echo "  The rocheckr script verifies the status of Roblox user profiles by checking their availability."
    echo
    echo "Arguments:"
    echo "  START_ID      The starting user ID to begin checking profiles. Default is 1 if not provided."
    echo "  END_ID        (Optional) The ending user ID to stop checking profiles. If provided, the script"
    echo "                will check profiles for all IDs in between START_ID and END_ID."
    echo
    echo "Options:"
    echo "  None"
    echo
    echo "Examples:"
    echo "  - Check a single user profile:"
    echo "    rocheckr 123"
    echo
    echo "  - Check profiles in a range:"
    echo "    rocheckr 100 150"
    echo
    echo "  - Check profiles starting from ID 50 without specifying an end ID:"
    echo "    rocheckr 50"
    echo
    echo "Note:"
    echo "  The script will run indefinitely if only the START_ID is provided. If both START_ID and END_ID"
    echo "  are provided, the script will check profiles for all IDs in the specified range."
    exit 0
fi

start_id=${1:-1}  # Use the first command-line argument as the starting user ID, default to 1 if not provided
end_id=$2

id=$start_id
retries=5  # Number of retries in case of failure
delay_on_retries=2  # Delay in seconds on the 3rd, 4th, and 5th retries

while [[ -z "$end_id" || $id -le $end_id ]]; do
    retries_left=$retries
    while [[ $retries_left -gt 0 ]]; do
        url="https://www.roblox.com/users/${id}/profile"
        response_url=$(curl --connect-timeout 2 -m 5 -s -L -o /dev/null -w "%{url_effective}" "$url")

        if [[ $? -eq 0 ]]; then
            break  # Successful request, exit retry loop
        fi

        retries_left=$((retries_left - 1))

        if [[ $retries_left -ge 2 ]]; then
            sleep 1  # Introduce a 1-second delay between retries for the 1st and 2nd retries
        else
            sleep $delay_on_retries  # Longer delay for the 3rd, 4th, and 5th retries
        fi
    done

    if [[ $retries_left -eq 0 ]]; then
        echo "Error: Curl request failed for user $id after $retries retries"
    elif [[ "$response_url" == "https://www.roblox.com/request-error?code=404" ]]; then
        echo -e "\e[91mUser \e[1m$id\e[0m \e[91mis \e[1mterminated\e[0m"  # Bold and red text
    elif [[ "$response_url" == "https://www.roblox.com/users/${id}/profile" ]]; then
        echo -e "\e[92mUser \e[1m$id\e[0m \e[92mis \e[1mactive\e[0m"  # Bold and green text
    else
        echo "Unexpected response for user $id: $response_url"
    fi

    # Delay
    # sleep 0.1
    id=$((id + 1))
done
