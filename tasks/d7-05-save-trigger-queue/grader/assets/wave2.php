<?php

/**
 * @file
 * Wave 2: a new insert plus a re-save (update path) — dedup must hold.
 */

$node = new stdClass();
$node->type = 'measurement';
$node->title = 'm-7-4.5';
$node->language = LANGUAGE_NONE;
$node->status = 1;
$node->field_clinic_id[LANGUAGE_NONE][0]['value'] = 7;
$node->field_value[LANGUAGE_NONE][0]['value'] = 4.5;
node_save($node);

// Update path: re-save an existing clinic-7 measurement unchanged.
$nid = (int) db_query("SELECT nid FROM {node} WHERE title = 'cs-m1'")->fetchField();
$existing = node_load($nid, NULL, TRUE);
node_save($existing);

print 'wave2-ok';
