#!/bin/bash
#set -x

CURRENT_DIR=`pwd`
user=`echo "$(whoami)"`
password=`cat /home/$user/pw.txt`

CALLEDPATH=`dirname $0`
case "$CALLEDPATH" in
  .*)
    CALLEDPATH="$PWD/$CALLEDPATH"
    ;;
esac

source "$CALLEDPATH/setup.conf";


get_target_directory() {
if [ ! -e $TARGET_DIR ]; then
  mkdir $TARGET_DIR
fi
echo $password | sudo -S chown www-data:www-editors -R $TARGET_DIR;
}

get_source_dump() {
  cd $SOURCE_DIR
  if [ $CMS = 'Drupal' ]; then
    vendor/bin/drush sql:dump --result-file=~/source_drupal.sql
  elif [ $CMS = 'Wordpress' ]; then
    wp db export ~/source_$CMS.sql
  fi


  mysqldump -u $SOURCE_MYSQL_USER -p$SOURCE_MYSQL_PASS --add-drop-table $SOURCE_CIVI_DB > ~/source_civicrm.sql
  sed -i 's/DEFINER=[^*]*\*/\*/g' ~/source_civicrm.sql
  sed -i 's/DEFINER=[^*]*\*/\*/g' ~/source_$CMS.sql
}

copy_source_to_target() {
  echo $password | sudo -S cp -R $SOURCE_DIR $TARGET_DIR
}

create_target_db() {
  echo "Create drupal database for target site";
  db_exists=`mysql -u $TARGET_MYSQL_USER -p$TARGET_MYSQL_PASS -e "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '$TARGET_DRUPAL_DB'" | wc -c`
  if [ $db_exists = 0 ]; then
    echo $password | sudo -S mysql -e "CREATE DATABASE $TARGET_DRUPAL_DB";
  fi
  db_exists=`mysql -u $TARGET_MYSQL_USER -p$TARGET_MYSQL_PASS -e "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '$TARGET_CIVI_DB'" | wc -c`
  if [ $db_exists = 0 ]; then
    echo "Create civicrm database for target site";
    echo $password | sudo -S mysql -e "CREATE DATABASE $TARGET_CIVI_DB";
  fi

  echo "Create mysql user for drupal database";
  echo $password | sudo -S mysql -e "GRANT ALL PRIVILEGES ON $TARGET_DRUPAL_DB.* TO '$TARGET_MYSQL_USER'@'localhost' IDENTIFIED BY '$TARGET_MYSQL_PASS';FLUSH PRIVILEGES;";
  echo "Create mysql user for civicrm database";
  echo $password | sudo -S mysql -e "GRANT ALL PRIVILEGES ON $TARGET_CIVI_DB.* TO '$TARGET_MYSQL_USER'@'localhost' IDENTIFIED BY '$TARGET_MYSQL_PASS';FLUSH PRIVILEGES;";
}

dump_target_db() {
  echo "Dumping target databases with source mysqldumps";
  mysql -u $TARGET_MYSQL_USER -p$TARGET_MYSQL_PASS $TARGET_DRUPAL_DB < ~/source_$CMS.sql
  mysql -u $TARGET_MYSQL_USER -p$TARGET_MYSQL_PASS $TARGET_CIVI_DB < ~/source_civicrm.sql
  echo "Remove source site mysqldumps"
  echo $password | sudo -S rm ~/source_$CMS.sql
  echo $password | sudo -S rm ~/source_civicrm.sql
}

help () {
echo "Usage: $0 {refreshsite|copysite|print_var|help}"
  echo "  refreshsite - Refresh a target/staging site with sql dumps of source/production site"
  echo "  copysite - Create a site using codebase and dumps of source site"
  echo "  print_var - Just to test if the variables are included from the source file"
  echo "  help - this help info"
}

case "$1" in
  refreshsite)
    get_source_dump
    dump_target_db
    ;;
  copysite)
    get_target_directory
    get_source_dump
    copy_source_to_target
    create_target_db
    dump_target_db
    ;;
  print_var)
    echo $CMS
    echo $TARGET_MYSQL_USER
    ;;
  help)
    help
    ;;
esac

exit $?
