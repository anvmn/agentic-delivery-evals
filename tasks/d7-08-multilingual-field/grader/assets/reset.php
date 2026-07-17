<?php

/**
 * @file
 * Reset the d7site to a known state for d7-08 grading (drush php-script).
 */

$nids = db_query("SELECT nid FROM {node} WHERE type = 'article'")->fetchCol();
if ($nids) {
  node_delete_multiple($nids);
}
if (field_info_field('field_body')) {
  field_delete_field('field_body');
}
field_purge_batch(500);
if (node_type_get_type('article')) {
  node_type_delete('article');
}
db_delete('system')->condition('name', 'langfield')->execute();
cache_clear_all('*', 'cache', TRUE);
print 'reset-ok';
