#!/bin/sh -u

YEAR=$(date +'%Y')
MONTH=$(date +'%m')
DAY=$(date +'%d')

if [ "$MONTH" = '1' ]; then
        ye=$((YEAR - 1))
        mon=12
elif [ "$MONTH" = '01'  ]; then
        ye=$((YEAR - 1))
        mon=12
else
        ye="$YEAR"
        mon=$((MONTH - 1))
fi

if ((mon < 10)); then
        mon='0'${mon}
fi


###
# variables
###
fileRemote="xxx.zip"
fileLocal="/xxx"

storageClass="COLD"

yaAccessIDF="xxx"
yaSecretKey="xxx"

region="ru-central1"
yaRegion="ru-central1"

httpReq='PUT'
authType='AWS4-HMAC-SHA256'
service='s3'

bucket="xxx"
baseUrl=".storage.yandexcloud.net"


###
# functions
###
my_sed() {
  if which gsed > /dev/null 2>&1; then
    gsed "$@"
  else
    sed "$@"
  fi
}

awsStringSign4() {
  kSecret="AWS4$1"
  kDate=$(printf         '%s' "$2" | openssl dgst -sha256 -hex -mac HMAC -macopt "key:${kSecret}"     2>/dev/null | my_sed 's/^.* //')
  kRegion=$(printf       '%s' "$3" | openssl dgst -sha256 -hex -mac HMAC -macopt "hexkey:${kDate}"    2>/dev/null | my_sed 's/^.* //')
  kService=$(printf      '%s' "$4" | openssl dgst -sha256 -hex -mac HMAC -macopt "hexkey:${kRegion}"  2>/dev/null | my_sed 's/^.* //')
  kSigning=$(printf 'aws4_request' | openssl dgst -sha256 -hex -mac HMAC -macopt "hexkey:${kService}" 2>/dev/null | my_sed 's/^.* //')
  signedString=$(printf  '%s' "$5" | openssl dgst -sha256 -hex -mac HMAC -macopt "hexkey:${kSigning}" 2>/dev/null | my_sed 's/^.* //')
  printf '%s' "${signedString}"
}

###
# end functions
###



###
# Initialize variables
###
# fileRemote="${fileLocal}"

if [ -z "${region}" ]; then
  region="${yaRegion}"
fi

dateValueS=$(date -u +'%Y%m%d')
dateValueL=$(date -u +'%Y%m%dT%H%M%SZ')

if hash file 2>/dev/null; then
  contentType="$(file --brief --mime-type "${fileLocal}")"
else
  contentType='application/octet-stream'
fi

# rewrite content type if you need
contentType="binary/octet-stream"



###
# starting
###

echo "Uploading" "${fileLocal}" "->" "${bucket}" "${region}" "${storageClass}"

###
# 0. Hash the file to be uploaded
###
if [ -f "${fileLocal}" ]; then
  payloadHash=$(openssl dgst -sha256 -hex < "${fileLocal}" 2>/dev/null | my_sed 's/^.* //')
else
  echo "File not found: '${fileLocal}'"
  exit 1
fi


###
# 1. Create canonical request (NOTE: order significant in ${headerList} and ${canonicalRequest})
###
headerList='Host;Content-Type;X-Amz-Content-SHA256;X-Amz-Date;X-Amz-Storage-Class'

canonicalRequest="${httpReq}
/${bucket}/${ye}/${fileRemote}

Host:
Content-Type:${contentType}
X-Amz-Content-SHA256:${payloadHash}
X-Amz-Date:${dateValueL}
X-Amz-Storage-Class:${storageClass}

${headerList}
${payloadHash}"

# Hash it
canonicalRequestHash=$(printf '%s' "${canonicalRequest}" | openssl dgst -sha256 -hex 2>/dev/null | my_sed 's/^.* //')

# Log if needed
# echo -e "$canonicalRequest" > ./our1.txt

###
# 2. Create string to sign
###
stringToSign="\
${authType}
${dateValueL}
${dateValueS}/${region}/${service}/aws4_request
${canonicalRequestHash}"

###
# 3. Sign the string
###
signature=$(awsStringSign4 "${yaSecretKey}" "${dateValueS}" "${region}" "${service}" "${stringToSign}")


###
# Uploading 
###
curl -i -X PUT -T "./${ye}/${fileRemote}" \
    -H "Host: ${bucket}.storage.yandexcloud.net" \
    -H "Content-Type: ${contentType}" \
    -H "X-Amz-Content-SHA256: ${payloadHash}" \
    -H "X-Amz-Date: ${dateValueL}" \
    -H "X-Amz-Storage-Class: ${storageClass}" \
    -H "Authorization: ${authType} Credential=${yaAccessIDF}/${dateValueS}/${region}/${service}/aws4_request, SignedHeaders=${headerList}, Signature=${signature}" \
"https://storage.yandexcloud.net/${bucket}/${ye}/${fileRemote}"







