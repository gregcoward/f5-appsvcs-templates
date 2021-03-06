#!/usr/bin/env bash
set -eu

package_file="${1:-package.json}"
product_name=$(jq -r .name "$package_file")
product_version=$(jq -r .version "$package_file" | cut -d - -f 1)

repo_url="https://$ARTIFACTORY_URL/artifactory/f5-automation-toolchain-generic/$product_name/$product_version"
curl_flags="--insecure --fail -H X-JFrog-Art-Api:$ARTIFACTORY_API_KEY"

# find files
pushd dist
files=$(ls --hide=*.sha256)
popd

# upload each file
for f in $files
do
    echo uploading "$f"

    # upload file
    curl $curl_flags -T "dist/$f" "$repo_url/$f"

    # calculate and upload checksums
    for chksm in sha256 sha1 md5; do
        "${chksm}sum" "dist/$f" > "dist/$f.$chksm"
        curl $curl_flags -T "dist/$f.$chksm" "$repo_url/$f.$chksm"
        if [ "$chksm" = "sha256" ]; then
            # sha file with hash and file name preserved
            curl $curl_flags -T "dist/$f.sha256" "$repo_url/$f.sha256.txt"
        rm "dist/$f.$chksm"
        fi
    done
done
