<?php

/**
 * @file
 * Reset the d7site to a known state for d7-07 grading (drush php-script).
 */

$nids = db_query("SELECT nid FROM {node} WHERE type = 'item'")->fetchCol();
if ($nids) {
  node_delete_multiple($nids);
}
if (field_info_field('field_code')) {
  field_delete_field('field_code');
}
field_purge_batch(500);
if (node_type_get_type('item')) {
  node_type_delete('item');
}
db_delete('system')->condition('name', 'bulknorm')->execute();
cache_clear_all('*', 'cache', TRUE);
print 'reset-ok';
