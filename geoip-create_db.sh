LINK_NRO_STATS="https://ftp.ripe.net/pub/stats/ripencc/nro-stats/latest/nro-delegated-stats"
LINK_NRO_MD5="https://ftp.ripe.net/pub/stats/ripencc/nro-stats/latest/nro-delegated-stats.md5"
DB_DIR=/usr/local/geoip/db
TMP_DB=/var/tmp/geoip
TMP_FILE=$TMP_DB/nro-delegated-stats
LOG_FILE=/var/log/geoipdb.log
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
  echo "* Creating dir $DB_DIR $TMP_DB"
else
  echo "* Directories $DB_DIR $TMP_DB already"
fi

md5_remote=$(wget -q -O- $LINK_NRO_MD5 |awk '{print $1}')
[[ -n $(ls $TMP_FILE-* 2>/dev/null) ]] && \
  md5_local=$(md5sum $(ls -t $TMP_FILE-* |head -n1) |awk '{print $1}') #&2>/dev/null)

if [[ $md5_remote != $md5_local ]]; then
  # download db
  echo " * Downloading $LINK_NRO_STATS" | tee -a $LOG_FILE
  wget -nv --show-progress --no-check-certificate -O $TMP_FILE $LINK_NRO_STATS || exit 1
  echo

  # set new name with creation time
  stat_file=$(stat -c %y $TMP_FILE) # -c %w
  date_file=$(echo $stat_file |awk '{print $1}' |sed 's/-//g')
  hour_file=$(echo $stat_file |awk '{print $2}' |cut -c1-8 |sed 's/://g')
  utc_file=$(echo $stat_file |awk '{print $3}')
  new_name="${TMP_FILE}-${date_file}-${hour_file}-UTC${utc_file}"
  cp --preserve $TMP_FILE $new_name
  echo "* DB file creation date: $date_file $hour_file UTC $utc_file" | tee -a $LOG_FILE


  # clear file with IPv4 and IPv6 only
  sed -Ei '/ipv4|ipv6/!d; /summary/d' $TMP_FILE

  countries=$(awk -F"|" '{print $2}' $TMP_FILE |sort -u)

  # set array map address available to network prefix
  convertQttAddrToPrefix

  # replace quantitty IP to mask
  echo " * Converting information IPv4 to network prefix"
  for qtt_address in ${!masks[@]}; do
    printf "  - prefix: ${masks[$qtt_address]}\t==\tqtt_prefix = $(grep -c "|${qtt_address}|" $TMP_FILE)\n" | tee -a $LOG_FILE
    sed -i "s#|${qtt_address}|#|${masks[$qtt_address]}|#g" $TMP_FILE
  done

  rm ${DB_DIR}/{ipv4,ipv6}/*.zone
  # create database directory
  echo; echo "* Creating DB in $DB_DIR for: "
  for code in $countries; do
    printf " $code"
    for version in ipv4 ipv6; do
      grep $code $TMP_FILE | grep $version | awk -F"|" '{print $4"/"$5}' >> "${DB_DIR}/${version}/${code,,}.zone"
    done
  done
  echo

else
  echo "* Your database already updated - ${md5_local}" && \
    echo "
$(date +%d-%m-%Y" "%H:%M) Your database already updated - ${md5_local}
" >> $LOG_FILE
fi
