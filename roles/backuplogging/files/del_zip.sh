
#!/bin/bash

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

# Удаляем файл бекапа отсюда
# xxx.zip
rm /xxx.zip

# Удаляем папку с бекапом
rm -r  /xxx/