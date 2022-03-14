#!/bin/bash




PORT=3310
HOST=127.0.0.1
USER=$GENNY_LOCAL_MYSQL_USER
PASSWORD=$GENNY_LOCAL_MYSQL_PASSWORD
DB=$GENNY_LOCAL_MYSQL_DB
PACKAGE="genny"

DELIM=":"


HELP="
------- PROTOGEN HELP ------- \n
-P - Sets the port. Defaults to 3310\n
-H - Sets the Hostname. Defaults to 127.0.0.1\n
-u - Sets the MySQL user. Defaults to \$GENNY_LOCAL_MYSQL_USER\n
-p - Sets the MySQL password. Defaults to \$GENNY_LOCAL_MYSQL_PASSWORD\n
-d - Sets the MySQL db. Defaults to \$GENNY_LOCAL_MYSQL_DB\n
-f - Sets the Package. Defaults to genny\n
-h - Displays this message
"


while getopts ":f:P:H:u:p:dh" opt
do

  case $opt in
    P)
      PORT=$OPTARG >&2
      ;;
    H)
      HOST=$OPTARG >&2
      ;;
    u)
      USER=$OPTARG >&2
      ;;
    p)
      PASSWORD=$OPTARG >&2
      ;;
    d)
      DB=$OPTARG >&2
      ;;
    f)
      PACKAGE=$OPTARG >&2
      ;;
    h)
      echo -e $HELP
      exit
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      echo -e $HELP
      exit
      ;;
  esac
done

if [ -z "$PORT" ]
then
  echo "Port is not set. Can set with -P"
  exit
fi

if [ -z "$HOST" ]
then
  echo "Hostname is not set. Can set with -H"
  exit
fi

if [ -z "$USER" ]
then
  echo "MySQL user is not set. Can set with -u \$GENNY_LOCAL_MYSQL_USER"
  exit
fi

if [ -z "$PASSWORD" ]
then
  echo "MySQL password is not set. Can set with -p \$GENNY_LOCAL_MYSQL_PASSWORD"
  exit
fi

if [ -z "$DB" ]
then
  echo "MySQL db is not set. Can set with -d \$GENNY_LOCAL_MYSQL_DB"
  exit
fi

FILTER=$@

if [ -z "$FILTER" ]
then
  FILTER="attribute baseentity baseentity_attribute baseentity_baseentity ask question question_question answer"
fi

./clear-protos.sh

TABLES=`mysql --port="$PORT" \
      --host="$HOST" \
      --user="$USER" \
      --password="$PASSWORD" \
      --database="$DB" \
      --execute="SHOW TABLES;"`

#Don't want the header table
firstTable=0

for table in $TABLES
do
    if [ $firstTable -eq 1 ]
    then


      if [[ "$FILTER" == *"$table"* ]]
      then

        # Get the fields of each table, grabbing only their name and type
        FIELDS=`mysql --port="$PORT" \
          --host="$HOST" \
          --user="$USER" \
          --password="$PASSWORD" \
          --database="$DB" \
          --execute="SELECT COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_NAME = '$table';"`

        # , 

        # We don't want the first two entries as those are just the header names
        count=0
        # I couldn't work out a better way to do this...
        second=0

        
        TABLE_FIELD_SET=""
        TABLE_META_SET=""

        echo --- TABLE: $table ---

        for field in $FIELDS
        do

          if [ $count -gt 0 ]
          then
            TABLE_FIELD_SET="$TABLE_FIELD_SET,$field"
            
            META=`mysql --port="$PORT" \
            --host="$HOST" \
            --user="$USER" \
            --password="$PASSWORD" \
            --database="$DB" \
            --execute="SELECT DATA_TYPE, IS_NULLABLE, COLUMN_KEY FROM information_schema.COLUMNS WHERE TABLE_NAME = '$table' AND COLUMN_NAME = '$field';"`
            META_SET=""
            metacount=0
            for metadata in $META
            do
              if [ $metacount -gt 2 ]
              then
                META_SET="$META_SET$DELIM$metadata"
                
              fi

              metacount=$((metacount+1))
            done
            TABLE_META_SET="$TABLE_META_SET,$META_SET"



          fi

          count=$((count+1))

        done

        ./create-proto.sh $PACKAGE $table $DELIM "$TABLE_FIELD_SET" "$TABLE_META_SET"

      fi

    fi
    firstTable=1
    
done
    