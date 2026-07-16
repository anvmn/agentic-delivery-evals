<?php

/**
 * @file
 * Reset the d7site to a known state for d7-03 grading (drush php-script).
 */

$nids = db_query("SELECT nid FROM {node} WHERE type = 'contact'")->fetchCol();
if ($nids) {
  node_delete_multiple($nids);
}
if (field_info_field('field_phone')) {
  field_delete_field('field_phone');
}
field_purge_batch(500);
if (node_type_get_type('contact')) {
  node_type_delete('contact');
}
db_delete('system')->condition('name', 'phonebook')->execute();
cache_clear_all('*', 'cache', TRUE);
print 'reset-ok';
