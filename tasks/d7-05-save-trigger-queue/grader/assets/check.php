<?php

/**
 * @file
 * State probe: queue depth and totals variables (drush php-script).
 */

$queue = (int) db_query("SELECT COUNT(*) FROM {queue} WHERE name = 'clinicstats_recalc'")->fetchField();
print drupal_json_encode(array(
  'queue' => $queue,
  't7' => variable_get('clinicstats_totals_7', NULL),
  't9' => variable_get('clinicstats_totals_9', NULL),
));
