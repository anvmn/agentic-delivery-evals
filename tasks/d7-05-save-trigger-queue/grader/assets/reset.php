<?php

/**
 * @file
 * Reset the d7site to a known state for d7-05 grading (drush php-script).
 */

$nids = db_query("SELECT nid FROM {node} WHERE type = 'measurement' OR title = 'cs-page-probe'")->fetchCol();
if ($nids) {
  node_delete_multiple($nids);
}
foreach (array('field_clinic_id', 'field_value') as $field_name) {
  if (field_info_field($field_name)) {
    field_delete_field($field_name);
  }
}
field_purge_batch(500);
if (node_type_get_type('measurement')) {
  node_type_delete('measurement');
}
db_delete('queue')->condition('name', 'clinicstats_recalc')->execute();
db_delete('variable')->condition('name', db_like('clinicstats') . '%', 'LIKE')->execute();
db_delete('system')->condition('name', 'clinicstats')->execute();
cache_clear_all('*', 'cache', TRUE);
cache_clear_all('variables', 'cache_bootstrap');
print 'reset-ok';
