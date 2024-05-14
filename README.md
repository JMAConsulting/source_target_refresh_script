## Refresh Target site with Source site's sqldumps and/or codebase

This script refresh a target site's CMS and CiviCRM databases with respective source databases or create a copy of source site as target site as per given target parmeters.

###Example

- Read help
```sh
$sh source_target_refresh.sh help
Usage: refreshsite.sh {refreshsite|drupal|createdb|droptables|solr_start|solr_stop|help}
  refreshsite - Refresh a target/staging site with sql dumps of source/production site
  copysite - Create a site using codebase and dumps of source site
  print_var - Just to test if the variables are included from the source file
  help - this help info

```

- Copy site
```sh
$sh source_target_refresh.sh copysite
```

- Copy site
```sh
$sh source_target_refresh.sh refreshsite
```
