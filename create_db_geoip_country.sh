NRO_STATS="https://ftp.ripe.net/pub/stats/ripencc/nro-stats/latest/nro-delegated-stats"
DB_DIR=/usr/local/geodb/db
TMP_DB=/usr/src
TMP_FILE=$TMP_DB/nro-delegated-stats

addressToMask() {
  declare -A masks

  for mask in {8..32}; do
    qtt_address=$((2 ** (32 - mask)))
    $masks["$qtt_address"]="$mask"
  done
}

If [[ ! -d $DB_DIR ]]; then
  mkdir -p $DB_DIR
fi

wget --no-check-certificate -P $TMP_FILE/ $NRO_STATS || exit 1

sed -i '/ipv4|ipv6/!d' $TMP_FILE

countries=$(awk -F"|" '{print $2}' $TMP_FILE |sort |uniq)

# replace quantitty IP to mask
for qtt_address in ${!masks[@]}; do
#TODO
echo qtt_ips=$qtt_address | mask=${masks[$qtt_address]} 
#  sed -i "s/$qtt_address/${masks[$qtt_address]}/g" $TMP_FILE
done

for code in ${countries[@]}; do
  for version in { ipv4 ipv6 }; do
    grep $code $TMP_FILE | grep $version | awk -F"|" '{print $4"/"$5}' >> ${DB_DIR}/${version}/${code,,}.zone
  done
done

