#!/bin/bash

YEAR=$(date +'%Y')
MONTH=$(date +'%m')
DAY=$(date +'%d')

#TEST
#YEAR=2019
#MONTH=06

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

#echo "ye: ${ye} ; mon: ${mon} ;"

# Делаем архив zip из бекапа
zip -P xxx -r /xx.zip /xxx/