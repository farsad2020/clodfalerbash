#!/bin/bash
echo  "Plaese inter Domain:"
read domain
echo  "Email zaccount cloudflare:"
read email_access
echo  "account id:"
read account_id
echo  "enter Api_key:"
read API_key
echo  "type of record:"
read type
echo  "name of record:"
read name
echo  "inter content of record:"
read content

zones=$(curl -X GET "https://api.cloudflare.com/client/v4/zones?name=${domain}&status=active&account.id=$account_id Account&page=1&per_page=20&order=status&direction=desc&match=all" \
     -H "X-Auth-Email: $email_access" \
     -H "X-Auth-Key: $API_key" \
     -H "Content-Type: application/json")

#echo "zones:" $zones

check=$(echo ${zones}|jq '.result[0].name'|sed 's/"//g')
#echo "result.name" $check

function add_zone(){
local donaim=$domain
local account_id=$accont_id
curl -X POST "https://api.cloudflare.com/client/v4/zones" \
     -H "X-Auth-Email: $email_access" \
     -H "X-Auth-Key: $API_key" \
     -H "Content-Type: application/json" \
     --data '{"name":${domain},"account":{"id":${accont_id}},"jump_start":true,"type":"full"}'
}


function updatezone(){

local domain=$domain
local account_id=$accont_id
local name=$name
local content=$content
        zoneid=$(echo ${zone}|jq '.result[0].id'|sed 's/"//g')

        records=$(curl -X GET "https://api.cloudflare.com/client/v4/zones/${zoneid}/dns_records?type=A&name=${check}&page=1&per_page=20&order=type&direction=desc&match=all" \
        -H "X-Auth-Email: $email_access" \
        -H "X-Auth-Key: $API_key" \
        -H "Content-Type: application/json")

echo "zoneid="$zoneid

        for i in  ${records}
        do
        if [$(echo ${records}|jq '.result[i].name'|sed 's/"//g')== ${name} ]
        then

# get the dns record id
        dnsrecordid=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records?type=A&name=${name}.${domain}" \
         -H "X-Auth-Email: $email_access" \
         -H "X-Auth-Key: $API_key" \
         -H "Content-Type: application/json" | jq -r '{"result"}[] | .[0] | .id')
#update dns record
        curl -X PUT "https://api.cloudflare.com/client/v4/zones/${zoneid}/dns_records/${dnsrecordid}" \
        -H "X-Auth-Email: $email_access" \
        -H "X-Auth-Key: $API_key" \
        -H "Content-Type: application/json" \
        --data '{"type":'"${type}"',"name":'"${name}.${domain}"',"content":"127.0.0.1","proxied":false}'
        else

 #add recorde
     curl -X POST "https://api.cloudflare.com/client/v4/zones/${zoneid}" \
     -H "X-Auth-Email: $email_access" \
     -H "X-Auth-Key: $API_key" \
     -H "Content-Type: application/json" \
     --data '{"type":"A","name":"${name}.${domain}","content":"${content}","ttl":3600,"priority":10,"proxied":false}'

        fi;
        done
}

function chengednsrecord()
{
local domain=$domain
local account_id=$account_id
local name=$name
local content=$content
local type=$type
zones=$(curl -X GET "https://api.cloudflare.com/client/v4/zones?name=$domain&status=active&account.id=$account_id Account&page=1&per_page=20&order=status&direction=desc&match=all" \
     -H "X-Auth-Email: fs.joody@hotmail.co.uk" \
     -H "X-Auth-Key: e55dafc5d4727b8d8539874f517b8602d3dce" \
     -H "Content-Type: application/json")
#echo "zones=" $zones
zoneid=$(echo ${zones}|jq '.result[0].id'|sed 's/"//g')
echo "zonid=" $zoneid

recordname=$name.$domain
echo recordname=$recordname



dnsrecord=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${zoneid}/dns_records?name=${recordname}" \
         -H "X-Auth-Email: $email_access" \
         -H "X-Auth-Key: $API_key" \
         -H "Content-Type: application/json")
         recordid=$(echo $dnsrecord |  grep -o '"id":"[^"]*'| cut -d'"' -f4)
echo "record="$(echo $dnsrecord |  grep -o '"content":"[^"]*'| cut -d'"' -f4)
echo "recordid=" $recordid
recordis=$(echo $dnsrecord|jq '.success')
echo recordis $recordis

if [ ! -z $recordid ]
then
        contcheck=$(echo $dnsrecord |  grep -o '"content":"[^"]*'| cut -d'"' -f4)
        if [ "$contcheck" == "$content" ]
        then
        echo there is record by the same content

        else
        # update record
        curl -X PUT "https://api.cloudflare.com/client/v4/zones/${zoneid}/dns_records/${recordid}" \
        -H "X-Auth-Email: $email_access" \
        -H "X-Auth-Key: $API_key"  \
        -H "Content-Type: application/json" \
        --data '{"type":"'${type}'","name":"'${recordname}'","content":"'${content}'","ttl":Auto}'
        echo "record updated"
        fi
else
#add record
     curl -X POST "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records" \
     -H "X-Auth-Email: $email_access" \
     -H "X-Auth-Key: $API_key" \
     -H "Content-Type: application/json" \
     --data '{"type":"'$type'","name":"'$recordname'","content":"'$content'","ttl":1,"proxied":false}'
        echo "record added"

fi
#echo curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${zoneid}/dns_records?name=${recordname}"


}


if [ ! -z $check ]
then
        chengednsrecord $domain $account_id $name $content $type
else
        add_zone $domain $account_id

        chengednsrecord $domain $account_id $name $content $type
fi;
