<?php

/**
 * @file
 * Seed messy phone data — the hidden holdout set (drush php-script).
 */

$values = array(
  '054 123 4567',
  '054-1234567',
  '(054) 123-4567',
  '0541234567',
  '+972541234567',
  '+972 54-123-4567',
);
foreach ($values as $i => $value) {
  $node = new stdClass();
  $node->type = 'contact';
  $node->title = 'contact-' . $i;
  $node->language = LANGUAGE_NONE;
  $node->field_phone[LANGUAGE_NONE][0]['value'] = $value;
  node_save($node);
}

// A contact with no phone value at all.
$node = new stdClass();
$node->type = 'contact';
$node->title = 'contact-empty';
$node->language = LANGUAGE_NONE;
node_save($node);

// A contact with two revisions, messy in both.
$node = new stdClass();
$node->type = 'contact';
$node->title = 'contact-rev';
$node->language = LANGUAGE_NONE;
$node->field_phone[LANGUAGE_NONE][0]['value'] = '052 111 2222';
node_save($node);
$node = node_load($node->nid, NULL, TRUE);
$node->revision = TRUE;
$node->field_phone[LANGUAGE_NONE][0]['value'] = '052-333-4444';
node_save($node);

$data = (int) db_query('SELECT COUNT(*) FROM {field_data_field_phone}')->fetchField();
$rev = (int) db_query('SELECT COUNT(*) FROM {field_revision_field_phone}')->fetchField();
print drupal_json_encode(array('data' => $data, 'rev' => $rev));
