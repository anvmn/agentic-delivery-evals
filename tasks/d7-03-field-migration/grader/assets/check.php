<?php

/**
 * @file
 * Post-update assertions dump (drush php-script).
 */

$data_values = db_query('SELECT field_phone_value FROM {field_data_field_phone} ORDER BY field_phone_value')->fetchCol();
$rev_nid = (int) db_query("SELECT nid FROM {node} WHERE title = 'contact-rev'")->fetchField();
$rev_values = db_query('SELECT field_phone_value FROM {field_revision_field_phone} WHERE entity_id = :nid ORDER BY revision_id', array(':nid' => $rev_nid))->fetchCol();
$data = (int) db_query('SELECT COUNT(*) FROM {field_data_field_phone}')->fetchField();
$rev = (int) db_query('SELECT COUNT(*) FROM {field_revision_field_phone}')->fetchField();
// install.inc is not loaded in a php-script bootstrap.
include_once DRUPAL_ROOT . '/includes/install.inc';
$schema = drupal_get_installed_schema_version('phonebook');

print drupal_json_encode(array(
  'data_values' => $data_values,
  'rev_values' => $rev_values,
  'counts' => array('data' => $data, 'rev' => $rev),
  'schema' => (int) $schema,
));
