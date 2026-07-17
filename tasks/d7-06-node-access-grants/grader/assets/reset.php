<?php

/**
 * @file
 * Reset the d7site to a known state for d7-06 grading (drush php-script).
 */

$nids = db_query("SELECT nid FROM {node} WHERE type = 'record'")->fetchCol();
if ($nids) {
  node_delete_multiple($nids);
}
foreach (array('ra_alice', 'ra_bob') as $name) {
  if ($u = user_load_by_name($name)) {
    user_delete($u->uid);
  }
}
foreach (array('field_center_id', 'field_user_center') as $field_name) {
  if (field_info_field($field_name)) {
    field_delete_field($field_name);
  }
}
field_purge_batch(500);
if (node_type_get_type('record')) {
  node_type_delete('record');
}
db_delete('system')->condition('name', 'recordaccess')->execute();
cache_clear_all('*', 'cache', TRUE);
// Restore the default "grant all" row so other work is unaffected.
node_access_rebuild();
print 'reset-ok';
