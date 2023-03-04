#!/bin/bash
set -e
# Set a timeout of 30 seconds for the git command
timeout=30

# Install jq if it's not already present
if ! command -v jq >/dev/null; then
	echo "Installing jq..."
	if command -v pip3 >/dev/null; then
		pip3 install jq
	else
		echo "Error: pip3 not found. Please install jq manually."
		exit 1
	fi
fi

if [ $# -ne 2 ]; then
	echo "Usage: $0 context username_or_orgname"
	echo "Example: $0 users ZarTek-Creole"
	exit 1
fi
context=$1
username_or_orgname=$2

# Function to handle the "detected dubious ownership in repository" error
handle_error() {
	echo "Detected dubious ownership in repository: $1"
	echo "Setting safe.directory to true... $(pwd)"
	git config --global --add safe.directory "$(pwd)"
}

clone_or_update_repo() {
	local repo_url=$1
	local repo_name=$(basename "$repo_url" .git)
	if [[ $repo_name =~ ^\. ]]; then
		echo "Skip $repo_name..."
		# Skip repositories whose names start with a '.'
		return
	fi
	if [ -d "$repo_name" ]; then
		# Try to update the repository
		(cd "$repo_name" && timeout $timeout git pull --recurse-submodules --depth=1 --quiet || handle_error "$repo_name")
	else
		# Try to clone the repository
		timeout $timeout git clone --recurse-submodules --depth=1 --quiet "$repo_url" || handle_error "$repo_name"
	fi
}

# Initialize the page number
page_number=1

# Initialize the counter
counter=1

# Get the total number of repositories that are not forks
total_repos=$(curl -s "https://api.github.com/$context/$username_or_orgname/repos?per_page=100&parent=null" | jq '. | length')

while [ $counter -le "$total_repos" ]; do

	# Fetch the list of repositories from the GitHub API
	repos=$(curl -s "https://api.github.com/$context/$username_or_orgname/repos?page=$page_number&per_page=100&parent=null" | jq -r '.[].clone_url')

	#Clone or update each repository
	for repo_url in $repos; do
		# Display the current count and the total number of repositories
		echo "Cloning or updating repository $counter/$total_repos: $(basename "$repo_url")"
		clone_or_update_repo "$repo_url"
		((counter = counter + 1))
	done

	#Break out of the loop if there are no more pages of results
	if [ -z "$repos" ]; then
		break
	fi

	page_number=$((page_number + 1))
done
