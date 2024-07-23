LINK_NRO_STATS="https://ftp.ripe.net/pub/stats/ripencc/nro-stats/latest/nro-delegated-stats"
LINK_NRO_MD5="https://ftp.ripe.net/pub/stats/ripencc/nro-stats/latest/nro-delegated-stats.md5"
DB_DIR=/usr/local/geodb/db
TMP_DB=/usr/src/geoip
TMP_FILE=$TMP_DB/nro-delegated-stats
declare -A masks

convertQttAddrToPrefix() {
  for prefix in {8..32}; do
    qtt_address=$((2 ** (32 - prefix)))
    masks["$qtt_address"]="$prefix"
  done
}

clear
if [[ ! -d $DB_DIR || ! -d $TMP_DB ]]; then
  mkdir -p $DB_DIR/{ipv4,ipv6} $TMP_DB
  echo "Create dir $DB_DIR $TMP_DB"
else
  echo "Directories $DB_DIR $TMP_DB already"
fi

md5_remote=$(wget -q -O- $LINK_NRO_MD5 |awk '{print $1}')
md5_local=$(md5sum $TMP_FILE |awk '{print $1}') #&2>/dev/null)

if [[ $md5_remote != $md5_local ]]; then
  # download db
  echo "Downloading $LINK_NRO_STATS"; echo
  wget --no-check-certificate -O $TMP_FILE $LINK_NRO_STATS || exit 1

  # set new name with creation time
  stat_file=$(stat -c %y $TMP_FILE) # -c %w
  date_file=$(echo $stat_file |awk '{print $1}' |sed 's/-//g')
  hour_file=$(echo $stat_file |awk '{print $2}' |cut -c1-8 |sed 's/://g')
  utc_file=$(echo $stat_file |awk '{print $3}')
  new_name="${TMP_FILE}-${date_file}-${hour_file}-UTC${utc_file}"
  cp --preserve $TMP_FILE $new_name
  echo "DB file creation date: $date_file $hour_file UTC $utc_file"
else
  echo "Your database already updated"
fi


# clear file with IPv4 and IPv6 only
sed -Ei '/ipv4|ipv6/!d; /summary/d' $TMP_FILE

countries=$(awk -F"|" '{print $2}' $TMP_FILE |sort -u)

# set array map address available to network prefix
convertQttAddrToPrefix

# replace quantitty IP to mask
echo "Converting information IPv4 to network prefix"
for qtt_address in ${!masks[@]}; do
  printf " - prefix: ${masks[$qtt_address]} \t==\t qtt_addr: ${qtt_address} \t|\t changes: $(grep -c "|${qtt_address}|" $TMP_FILE)\n"
  sed -i "s#|${qtt_address}|#|${masks[$qtt_address]}|#g" $TMP_FILE
done

rm ${DB_DIR}/{ipv4,ipv6}/*.zone
# create database directory
echo "Creating DB for: "
for code in $countries; do
  printf " $code"
  for version in ipv4 ipv6; do
    grep $code $TMP_FILE | grep $version | awk -F"|" '{print $4"/"$5}' >> "${DB_DIR}/${version}/${code,,}.zone"
  done
done
