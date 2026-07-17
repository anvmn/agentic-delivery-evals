<?php

/**
 * @file
 * Seed 120 lowercase-coded items, then drive the update hook in a controlled
 * loop measuring per-pass progress (drush php-script). Prints JSON.
 */

// Seed only if not already present (grader installs fresh each run).
$existing = (int) db_query("SELECT COUNT(*) FROM {node} WHERE type = 'item'")->fetchField();
if ($existing == 0) {
  for ($i = 0; $i < 120; $i++) {
    $node = new stdClass();
    $node->type = 'item';
    node_object_prepare($node);
    $node->title = 'item-' . $i;
    $node->language = LANGUAGE_NONE;
    $node->status = 1;
    $node->uid = 1;
    $node->field_code[LANGUAGE_NONE][0]['value'] = 'code-abc-' . $i;
    node_save($node);
  }
}

module_load_install('bulknorm');

$upper_sql = "SELECT COUNT(*) FROM {field_data_field_code} WHERE BINARY field_code_value = UPPER(field_code_value)";

$sandbox = array();
$passes = 0;
$prev = 0;
$maxdelta = 0;
do {
  bulknorm_update_7100($sandbox);
  $passes++;
  $done = (int) db_query($upper_sql)->fetchField();
  $delta = $done - $prev;
  if ($delta > $maxdelta) {
    $maxdelta = $delta;
  }
  $prev = $done;
  $finished = isset($sandbox['#finished']) ? $sandbox['#finished'] : 0;
} while ($finished < 1 && $passes < 200);

$total = (int) db_query("SELECT COUNT(*) FROM {field_data_field_code}")->fetchField();
$upper = (int) db_query($upper_sql)->fetchField();

print drupal_json_encode(array(
  'passes' => $passes,
  'maxdelta' => $maxdelta,
  'total' => $total,
  'upper' => $upper,
  'finished' => $finished,
));
